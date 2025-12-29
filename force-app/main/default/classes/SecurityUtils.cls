public with sharing class SecurityUtils {

    // Metoda do zamazywania PESELi i E-maili
    public static String maskSensitiveData(String input) {
        if (String.isBlank(input)) return input;

        String masked = input;

        // 1. Maskowanie PESEL (ciąg 11 cyfr)
        // Znajduje 11 cyfr i zamienia na [PESEL HIDDEN]
        Pattern peselPattern = Pattern.compile('\\b\\d{11}\\b'); 
        Matcher peselMatcher = peselPattern.matcher(masked);
        masked = peselMatcher.replaceAll('[PESEL HIDDEN]');

        // 2. Maskowanie Email (prosty regex)
        Pattern emailPattern = Pattern.compile('([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.[a-zA-Z0-9_-]+)');
        Matcher emailMatcher = emailPattern.matcher(masked);
        masked = emailMatcher.replaceAll('[EMAIL HIDDEN]');

        return masked;
    }
}