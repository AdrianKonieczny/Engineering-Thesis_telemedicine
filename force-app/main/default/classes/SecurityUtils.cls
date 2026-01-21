/**
 * @description Utility class providing data sanitization methods to ensure GDPR/RODO compliance.
 * Used primarily to scrub sensitive PII (Personally Identifiable Information) from logs and error messages.
 * @author AK
 */
public with sharing class SecurityUtils {

    /**
     * @description Scans the input string for patterns resembling PESEL numbers or Email addresses
     * and replaces them with placeholders to prevent data leaks.
     * @param input Raw string text
     * @return Sanitized string with PII removed
     */
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