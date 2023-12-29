Forked from [TheFreeman193's repo](https://github.com/TheFreeman193/PIFS) with additions such as:

- Flag tested profiles by moving them into a 'tested' folder, these will not be selected again during next run
- Fallback to check for alternative ABI folder automatically, with similar ABI in path name, e.g., if the detected ABI is "arm64-v8a", after all JSONs have been tested in the main folder "arm64-v8a", it will also use JSONs from the following folders:
  - arm64-v8a,armeabi-v7a,armeabi
  - x86_64,arm64-v8a,x86,armeabi-v7a,armeabi
  - x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
  - x86_64,x86,armeabi-v7a,armeabi,arm64-v8a
