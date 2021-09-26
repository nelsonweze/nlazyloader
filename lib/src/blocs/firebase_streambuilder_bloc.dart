import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nlazyloader/src/utils/util.dart';

class FBStreamBuilderState {
  List<DocumentSnapshot<Map<String, dynamic>>> documents;
  LoadingStatus loadingStatus;
  DocumentSnapshot? lastDocumentSnap;
  Query<Map<String, dynamic>>? query;
  bool hasReachedMax;
  FBStreamBuilderState(
      {this.documents = const [],
      this.loadingStatus = LoadingStatus.STABLE,
      this.lastDocumentSnap,
      this.hasReachedMax = false,
      this.query});

  FBStreamBuilderState copyWith(
      {List<DocumentSnapshot<Map<String, dynamic>>>? documents,
      LoadingStatus? loadingStatus,
      DocumentSnapshot? lastDocumentSnap,
      Query<Map<String, dynamic>>? query,
      bool? hasReachedMax}) {
    return FBStreamBuilderState(
        documents: documents ?? this.documents,
        lastDocumentSnap: lastDocumentSnap ?? this.lastDocumentSnap,
        loadingStatus: loadingStatus ?? this.loadingStatus,
        query: query ?? this.query,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax);
  }
}

class FBStreamBuilderCubit extends Cubit<FBStreamBuilderState> {
  FBStreamBuilderCubit() : super(FBStreamBuilderState());
  StreamSubscription? sub;

  void init(Query<Map<String, dynamic>> query) {
    emit(state.copyWith(query: query, loadingStatus: LoadingStatus.LOADING));
    sub = query.snapshots().listen((event) {
      onChangeData(event.docChanges);
    });
  }

  void onChangeData(
      List<DocumentChange<Map<String, dynamic>>> documentChanges) {
    var isChange = false;
    var documents = state.documents.toList();
    documentChanges.forEach((docChange) {
      if (docChange.type == DocumentChangeType.added) {
        isChange = true;
        documents.add(docChange.doc);
        emit(state.copyWith(hasReachedMax: false));
      } else if (docChange.type == DocumentChangeType.removed) {
        documents.removeWhere((doc) {
          return docChange.doc.id == doc.id;
        });
        isChange = true;
      } else {
        if (docChange.type == DocumentChangeType.modified) {
          int indexWhere = documents.indexWhere((doc) {
            return docChange.doc.id == doc.id;
          });
          if (indexWhere >= 0) {
            documents[indexWhere] = docChange.doc;
          }
          isChange = true;
        }
      }
    });
    if (isChange) {
      emit(state.copyWith(
          documents: documents,
          lastDocumentSnap: documents.last,
          loadingStatus: LoadingStatus.STABLE));
    }
  }

  Future<bool> requestNextPage(int count) async {
    if (state.loadingStatus == LoadingStatus.STABLE && !state.hasReachedMax) {
      print('loadmore');
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      emit(state.copyWith(loadingStatus: LoadingStatus.RETRIEVING));
      var documents = state.documents;
      if (state.query != null) {
        if (documents.isEmpty) {
          querySnapshot = await state.query!.get();
        } else {
          var snap = state.query!;
          if (state.lastDocumentSnap != null) {
            snap = snap.startAfterDocument(state.lastDocumentSnap!);
          }
          querySnapshot = await snap.limit(count).get();
        }

        int oldSize = documents.length;
        documents.addAll(querySnapshot.docs);
        int newSize = documents.length;
        if (oldSize != newSize) {
          emit(state.copyWith(documents: documents));
        } else
          emit(state.copyWith(hasReachedMax: true));
      }
    }
    emit(state.copyWith(loadingStatus: LoadingStatus.STABLE));
    return true;
  }

  @override
  Future<void> close() {
    sub?.cancel();
    return super.close();
  }
}
