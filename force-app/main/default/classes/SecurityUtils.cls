public with sharing class SecurityUtils {

    public static String maskSensitiveData(String input) {
        if (String.isBlank(input)) return input;

        String masked = input;

        Pattern peselPattern = Pattern.compile('\\b\\d{11}\\b'); 
        Matcher peselMatcher = peselPattern.matcher(masked);
        masked = peselMatcher.replaceAll('[PESEL HIDDEN]');

        Pattern emailPattern = Pattern.compile('([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.[a-zA-Z0-9_-]+)');
        Matcher emailMatcher = emailPattern.matcher(masked);
        masked = emailMatcher.replaceAll('[EMAIL HIDDEN]');

        return masked;
    }
}