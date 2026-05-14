%%{
  machine tstr_common;

  action mark { mark = fpc; }

  action set_year {
    if (!tstr_token_parse_year(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      fbreak;
    }
    tstr_parsed_set_year4(parsed, v);
  }

  action set_year2 {
    if (!tstr_token_parse_year(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      fbreak;
    }
    tstr_parsed_set_year2(parsed, v);
  }

  action set_month {
    if (!tstr_token_parse_month(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      fbreak;
    }
    tstr_parsed_set_month(parsed, v);
  }

  action set_day {
    if (!tstr_token_parse_day(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      fbreak;
    }
    tstr_parsed_set_day(parsed, v);
  }

  action set_day_name {
    if (!tstr_token_parse_day_name(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      fbreak;
    }
    tstr_parsed_set_day_name(parsed, v);
  }

  action set_hour {
    if (!tstr_token_parse_hour(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      fbreak;
    }
    tstr_parsed_set_hour(parsed, v);
  }

  action set_minute {
    if (!tstr_token_parse_minute(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      fbreak;
    }
    tstr_parsed_set_minute(parsed, v);
  }

  action set_second {
    if (!tstr_token_parse_second(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      fbreak;
    }
    tstr_parsed_set_second(parsed, v);
  }

  action set_fraction {
    if (!tstr_token_parse_fraction(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      fbreak;
    }
    tstr_parsed_set_fraction(parsed, v);
  }

  action set_tz_offset {
    if (!tstr_token_parse_tz_offset(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      fbreak;
    }
    tstr_parsed_set_offset(parsed, v);
  }

  action set_tz_utc {
    tstr_parsed_set_tz_utc(parsed, mark, fpc - mark);
  }

  action set_tz_abbrev {
    tstr_parsed_set_tz_abbrev(parsed, mark, fpc - mark);
  }

  action set_tz_annotation {
    tstr_parsed_set_tz_annotation(parsed, mark, fpc - mark);
  }

  action set_meridiem {
    if (!tstr_token_parse_meridiem(mark, fpc - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      fbreak;
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
}%%
