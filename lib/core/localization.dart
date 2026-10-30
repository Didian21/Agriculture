enum AppLanguage { tagalog, english }

const List<String> monthNamesEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> monthNamesTl = [
  'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
  'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre',
];

const List<String> dayNamesEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const List<String> dayNamesTl = [
  'Lunes', 'Martes', 'Miyerkules', 'Huwebes', 'Biyernes', 'Sabado', 'Linggo',
];

List<String> getMonthNames(bool isTagalog) => isTagalog ? monthNamesTl : monthNamesEn;
List<String> getDayNames(bool isTagalog) => isTagalog ? dayNamesTl : dayNamesEn;

String translateCrop(String crop, bool isTagalog) {
  if (!isTagalog) return crop;
  switch (crop) {
    case 'Rice':
      return 'Palay';
    case 'Eggplant':
      return 'Talong';
    case 'Tomato':
      return 'Kamatis';
    case 'String beans':
      return 'Sitaw';
    case 'Banana':
      return 'Saging';
    default:
      return crop;
  }
}
