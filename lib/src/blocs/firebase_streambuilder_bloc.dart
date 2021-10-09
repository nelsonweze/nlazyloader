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
  String error;
  FBStreamBuilderState(
      {this.documents = const [],
      this.loadingStatus = LoadingStatus.STABLE,
      this.lastDocumentSnap,
      this.hasReachedMax = false,
      this.error = '',
      this.query});

  FBStreamBuilderState copyWith(
      {List<DocumentSnapshot<Map<String, dynamic>>>? documents,
      LoadingStatus? loadingStatus,
      DocumentSnapshot? lastDocumentSnap,
      Query<Map<String, dynamic>>? query,
      String? error,
      bool? hasReachedMax}) {
    return FBStreamBuilderState(
        documents: documents ?? this.documents,
        lastDocumentSnap: lastDocumentSnap ?? this.lastDocumentSnap,
        loadingStatus: loadingStatus ?? this.loadingStatus,
        query: query ?? this.query,
        error: error ?? this.error,
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
    }, onError: (err) {
      print(err);
      emit(state.copyWith(loadingStatus: LoadingStatus.STABLE, error: err));
    });
  }

  void onChangeData(
      List<DocumentChange<Map<String, dynamic>>> documentChanges) {
    var isChange = false;
    var documents = state.documents.toList();
    var newDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
    if (documentChanges.isEmpty) {
      return emit(state.copyWith(
          documents: documents, loadingStatus: LoadingStatus.STABLE));
    }
    documentChanges.forEach((docChange) {
      if (docChange.type == DocumentChangeType.added) {
        isChange = true;
        newDocs.add(docChange.doc);
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
      var map = Map<String, DocumentSnapshot<Map<String, dynamic>>>();
      (newDocs + documents).forEach((element) {
        map[element.id] = element;
      });
      emit(state.copyWith(
          documents: map.values.toList(),
          lastDocumentSnap: map.values.last,
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
        if (querySnapshot.docs.isNotEmpty) {
          documents.addAll(querySnapshot.docs);
          var map = Map<String, DocumentSnapshot<Map<String, dynamic>>>();
          documents.forEach((element) {
            map[element.id] = element;
          });
          emit(state.copyWith(
              documents: map.values.toList(),
              lastDocumentSnap: map.values.last));
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
