import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming/firebase/storeage_methods.dart';
import 'package:live_streaming/models/live_stream.dart';
import 'package:live_streaming/providers/user_provider.dart';
import 'package:live_streaming/utils/utils.dart';
import 'package:provider/provider.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageMethods _storageMethods = StorageMethods();

  Future<String> startLiveStream(
      BuildContext context, String title, Uint8List? image) async {
    // final userpro = Provider.of<UserProvider>(context, listen: false);
    // print(userpro.user.uid);
    String channelId = '';
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String username = FirebaseAuth.instance.currentUser!.displayName!;
    try {
      if (title.isNotEmpty && image != null) {
        if (!((await _firestore
                .collection('livestream')
                .doc('${uid}${username}')
                .get())
            .exists)) {
          String thumbnailUrl = await _storageMethods.uploadImageToStorage(
            'livestream-thumbnails',
            image,
            uid,
          );
          channelId = '${uid}${username}';

          LiveStream liveStream = LiveStream(
            title: title,
            image: thumbnailUrl,
            uid: uid,
            username: username,
            viewers: 0,
            channelId: channelId,
            startedAt: DateTime.now(),
          );

          _firestore
              .collection('livestream')
              .doc(channelId)
              .set(liveStream.toMap());
        } else {
          showSnackBar(
              context, 'Two Livestreams cannot start at the same time.');
        }
      } else {
        showSnackBar(context, 'Please enter all the fields');
      }
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
    return channelId;
  }

  // Future<void> chat(String text, String id, BuildContext context) async {
  //   final user = Provider.of<UserProvider>(context, listen: false);

  //   try {
  //     String commentId = const Uuid().v1();
  //     await _firestore
  //         .collection('livestream')
  //         .doc(id)
  //         .collection('comments')
  //         .doc(commentId)
  //         .set({
  //       'username': user.user.username,
  //       'message': text,
  //       'uid': user.user.uid,
  //       'createdAt': DateTime.now(),
  //       'commentId': commentId,
  //     });
  //   } on FirebaseException catch (e) {
  //     showSnackBar(context, e.message!);
  //   }
  // }

  Future<void> updateViewCount(String id, bool isIncrease) async {
    try {
      await _firestore.collection('livestream').doc(id).update({
        'viewers': FieldValue.increment(isIncrease ? 1 : -1),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> endLiveStream(String channelId) async {
    try {
      QuerySnapshot snap = await _firestore
          .collection('livestream')
          .doc(channelId)
          .collection('comments')
          .get();

      for (int i = 0; i < snap.docs.length; i++) {
        await _firestore
            .collection('livestream')
            .doc(channelId)
            .collection('comments')
            .doc(
              ((snap.docs[i].data()! as dynamic)['commentId']),
            )
            .delete();
      }
      await _firestore.collection('livestream').doc(channelId).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
