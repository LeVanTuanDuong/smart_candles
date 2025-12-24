enum MoodType {
  stressed('Căng thẳng / Lo âu', '😟', 'Lavender', 'Thư giãn, giảm lo âu'),
  sad('Buồn / Trầm', '😢', 'Sweet Orange', 'Nâng cao tinh thần'),
  tired('Mệt mỏi', '😴', 'Peppermint', 'Tỉnh táo'),
  normal('Bình thường / Tích cực', '😊', 'Chamomile', 'Duy trì cảm xúc tích cực'),
  insomnia('Khó ngủ', '😴', 'Chamomile', 'An thần, hỗ trợ giấc ngủ');

  final String label;
  final String emoji;
  final String essentialOil;
  final String effect;

  const MoodType(this.label, this.emoji, this.essentialOil, this.effect);
}

