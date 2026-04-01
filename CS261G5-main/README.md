Flutter setup:
1. Download and extract the Flutter SDK from https://docs.flutter.dev/install (this should also install dart).
2. Add the absolute path of the SDK installation to the PATH environment variable.
3. You can run 'flutter doctor' in the command line to check the current installation of Flutter - we rely on 3.41.0. The Android toolchain is not needed for this project so do not worry if it comes up as an issue.

Creating an app:
1. In the desired directory, run 'flutter create -e --project-name=air_traffic_sim --platforms=windows,macos,linux .' (be wary of the final '.'). This will create the boilerplate (for this specific application) in which the app runs. You can run 'flutter create -h' to explore other options for creating your own app to learn and toy around with.
2. The main source code will belong to './lib'. This is primarily where you should be working. There may be an additional assets folder that will be used for any needed external assets - this will require editing of the 'pubspec.yaml' file.

Running the app:
1. To open the boilerplate app, run 'flutter run'. This will by default enable all assertions, along with debugging information enabling tools like DevTools to be able to connect to the process. Compilation is also optimised for fast development and run cycles (re-compilation), but not for execution speed or sys_binary size.
2. Hitting 'r' in the terminal whilst the app is running will trigger a quick reload, recompiling any changes that have been made since the last compilation and showing said changes in the app. 
3. 'flutter test' can be used to run unit tests defined within the './tests' folder.

The Flutter documentation is very well done. To learn more about how to use Flutter and Dart, visit https://flutter.dev/development .
It is suggested to first run these commands before pulling the repository, as often IDE specific files may be generated for your machine.
