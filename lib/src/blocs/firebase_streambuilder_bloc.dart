import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nlazyloader/src/utils/util.dart';

class FBStreamBuilderState {
  List<DocumentSnapshot<Map<String, dynamic>>> documents;
  LoadingStatus loadingStatus;
  DocumentSnapshot? lastDocumentSnap;
  Query<Map<String, dynamic>>? query;
  FBStreamBuilderState(
      {this.documents = const [],
      this.loadingStatus = LoadingStatus.STABLE,
      this.lastDocumentSnap,
      this.query});

  FBStreamBuilderState copyWith(
      {List<DocumentSnapshot<Map<String, dynamic>>>? documents,
      LoadingStatus? loadingStatus,
      DocumentSnapshot? lastDocumentSnap,
      Query<Map<String, dynamic>>? query}) {
    return FBStreamBuilderState(
        documents: documents ?? this.documents,
        lastDocumentSnap: lastDocumentSnap ?? this.lastDocumentSnap,
        loadingStatus: loadingStatus ?? this.loadingStatus,
        query: query ?? this.query);
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
      if (documents.isEmpty && docChange.type == DocumentChangeType.added) {
        isChange = true;
        print(docChange.type);
        documents.add(docChange.doc);
      }
      if (docChange.type == DocumentChangeType.removed) {
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
    if (state.loadingStatus == LoadingStatus.STABLE) {
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      emit(state.copyWith(loadingStatus: LoadingStatus.RETRIEVING));
      var documents = state.documents;
      if (state.query != null) {
        if (documents.isEmpty) {
          querySnapshot = await state.query!.get();
        } else {
          querySnapshot = await state.query!
              .startAfterDocument(state.lastDocumentSnap!)
              .limit(count)
              .get();
        }

        int oldSize = documents.length;
        documents.addAll(querySnapshot.docs);
        int newSize = documents.length;
        if (oldSize != newSize) {
          emit(state.copyWith(documents: documents));
        }
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
