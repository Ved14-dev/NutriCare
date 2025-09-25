class NutritionChatBot {
    static Future<String> getResponse(String input) async {
        if (input.toLowerCase().contains('rice')) {
            return 'A cup of cooked rice has about 200 calories.';
        }
        if (input.toLowerCase().contains('banana')) {
            return 'A medium banana has around 105 calories.';
        }
        return 'Sorry, I can help with calories of rice or banana for now.';
    }
}
