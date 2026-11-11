import 'package:bloc/bloc.dart';
import 'package:chat_with_firbase/features/auth/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  final List<UserModel> users = [];

  DocumentSnapshot<Map<String,dynamic>>? lastDocument;

  String currentSearchText ='';

  bool hasMore =true;

  bool isLoadingMore = false;

  int searchRequestID =0;

  static const int pageSize =10;

  Future<void> searchUsers(
    {required String value}
    )async
    {
      String searchText = value.toLowerCase().trim();
       
      final requestID = ++searchRequestID;

      if(searchText.isEmpty){
        users.clear();
        lastDocument=null;
        currentSearchText="";
        hasMore=false;
        isLoadingMore=false;
        emit(SearchInitial());
        return;
      }

      currentSearchText = searchText;
      users.clear();
      hasMore = true;
      isLoadingMore = false;
      emit(SearchLoading());

      try{
        final Snapshot = await FirebaseFirestore.instance
            .collection("users")
            .orderBy('searchName')
            .startAt([searchText])
            .endAt(['$searchText\uf8ff'])
            .limit(pageSize)
            .get();

        if(requestID !=searchRequestID){
          return;
        }

        if(Snapshot.docs.isNotEmpty){
          lastDocument = Snapshot.docs.last;
        }

        hasMore = Snapshot.docs.length == pageSize;

        final currentUserID = FirebaseAuth.instance.currentUser?.uid;
        final firstPageUser = Snapshot.docs
                                      .where((document)=> document.id !=currentUserID)
                                      .map((document)=> UserModel.fromMap({...document.data(),'uid' : document.id})
                                      )
                                      .toList();
        users.addAll(firstPageUser);

        if(users.isEmpty){
          emit(SearchEmpty());
          return;
        }

        emit(
          SearchSuccess(users: List.unmodifiable(users), 
                        hasMore: hasMore,
                        isLoadingMore : false
                        )
                      );
                                  


      }on FirebaseAuthException catch  (e){
        if(requestID != searchRequestID)return;
        emit(SearchFailure(message: e.message ?? " "));
        print(e);
      }catch (e){
        print(e);
      }
  }
}
