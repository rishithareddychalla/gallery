// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class PhotosLibraryApiClient {
  PhotosLibraryApiClient(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  Future<http.Response> get(String url) async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      print('Making GET request to: $url');
      final headers = await user.authHeaders;
      print('Auth headers: ${headers.keys}');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('GET response status: ${response.statusCode}');

      return response;
    } catch (e) {
      print('Error in GET request: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String url, String json) async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      print('Making POST request to: $url');
      final headers = await user.authHeaders;
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json,
      );
      print('POST response status: ${response.statusCode}');

      return response;
    } catch (e) {
      print('Error in POST request: $e');
      rethrow;
    }
  }

  Future<String> upload(File image) async {
    final String filename = path.basename(image.path);
    final request = http.StreamedRequest(
      'POST',
      Uri.parse('https://photoslibrary.googleapis.com/v1/uploads'),
    );
    request.headers.addAll(await _googleSignIn.currentUser!.authHeaders);
    request.headers['Content-Type'] = 'application/octet-stream';
    request.headers['X-Goog-Upload-File-Name'] = filename;
    request.headers['X-Goog-Upload-Protocol'] = 'raw';
    request.contentLength = image.lengthSync();
    image.openRead().listen(
      request.sink.add,
      onDone: request.sink.close,
      onError: request.sink.addError,
    );
    final http.StreamedResponse response = await request.send();
    return response.stream.bytesToString();
  }
}
