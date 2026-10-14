# Innings pitched are base-3. 4.2 means four innings and two outs, so
# 4.2 + 0.1 is five innings, not 4.3. Every innings figure in the report
# is carried as outs for this reason, and these tests pin that down.

fns <- load_report_functions(c("as_num", "ip_to_outs", "outs_to_ip_chr",
                               "outs_to_ip_num", "rate_per"))

ip_to_outs     <- fns$ip_to_outs
outs_to_ip_chr <- fns$outs_to_ip_chr
outs_to_ip_num <- fns$outs_to_ip_num
rate_per       <- fns$rate_per

expect("whole innings convert to thirds",
       ip_to_outs(c(0, 1, 5, 9)), c(0, 3, 15, 27))

expect("the .1 and .2 suffixes are outs, not tenths",
       ip_to_outs(c(4.1, 4.2, 6.1)), c(13, 14, 19))

expect("an impossible .3 suffix is floored rather than carried",
       ip_to_outs(4.3), 12)

expect("non-numeric innings become NA, not zero",
       ip_to_outs(c("x", NA)), c(NA_real_, NA_real_))

expect("outs render back as innings",
       outs_to_ip_chr(c(0, 13, 14, 15)), c("0.0", "4.1", "4.2", "5.0"))

expect("NA outs stay NA on the way back",
       outs_to_ip_chr(NA), NA_character_)

# The round trip is the property that matters: any legal innings value
# must survive conversion to outs and back unchanged.
legal <- c(0, 0.1, 0.2, 1, 1.1, 1.2, 4.1, 4.2, 7, 8.2, 9)
expect("every legal innings value survives a round trip",
       outs_to_ip_chr(ip_to_outs(legal)),
       c("0.0", "0.1", "0.2", "1.0", "1.1", "1.2",
         "4.1", "4.2", "7.0", "8.2", "9.0"))

# Two thirds of an inning is 0.667 of an inning, which is what an ERA
# denominator needs. Treating 4.2 as 4.2 inflates ERA by ~1%.
expect("outs convert to a true decimal for rate denominators",
       round(outs_to_ip_num(ip_to_outs(4.2)), 4), 4.6667)

expect("a nine-inning, three-run outing is a 3.00 ERA",
       round(rate_per(3, outs_to_ip_num(ip_to_outs(9)), 9), 2), 3)

expect("ERA off a 4.2 IP outing uses 4.667, not 4.2",
       round(rate_per(2, outs_to_ip_num(ip_to_outs(4.2)), 9), 2), 3.86)

expect("a zero denominator yields NA rather than Inf",
       rate_per(5, 0, 9), NA_real_)

expect("a negative denominator yields NA",
       rate_per(5, -1, 9), NA_real_)
