class AppText {
  static String lang = 'ko'; 

  static Map<String, Map<String, String>> values = {
    'ko': {
      'app_title': 'K-Path', // 1.4.2 삭제
      'walk': '걷기', 'hike': '등산', 'bike': '자전거', 'run': '달리기',
      'settings': '설정', 'user_set': '사용자 설정', 'lang_set': '언어 설정',
      'notif_set': '알림 설정', 'version': '앱 버전', 'save': '저장하기',
      'id': '아이디', 'name': '이름', 'age': '나이', 'weight': '체중 (kg)',
      'exercise_start': '시작하기', 'exercise_finish': '운동종료',
      'time': '시간', 'dist': '거리', 'avg': '평균', 'kcal': 'kcal',
      'photo_done': '사진 저장 완료!', 'save_ask': '기록을 저장할까요?',
      'cancel': '취소', 'save_btn': '저장',
    },
    'en': {
      'app_title': 'K-Path', // 1.4.2 삭제
      'walk': 'Walk', 'hike': 'Hike', 'bike': 'Bike', 'run': 'Run',
      'settings': 'Settings', 'user_set': 'User Settings', 'lang_set': 'Language',
      'notif_set': 'Notifications', 'version': 'Version', 'save': 'Save',
      'id': 'ID', 'name': 'Name', 'age': 'Age', 'weight': 'Weight (kg)',
      'exercise_start': 'START', 'exercise_finish': 'FINISH',
      'time': 'TIME', 'dist': 'DIST', 'avg': 'AVG', 'kcal': 'KCAL',
      'photo_done': 'Photo Saved!', 'save_ask': 'Save Workout?',
      'cancel': 'Cancel', 'save_btn': 'Save',
    }
  };

  static String get(String key) => values[lang]![key] ?? key;
}