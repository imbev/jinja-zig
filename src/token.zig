pub const TokenType = enum {
    BACKSLASH,
    LBRACE,
    RBRACE,
    NUMBER_SIGN,
    PERCENT,
    QUOTE,
    DOUBLE_QUOTE,
    //
    STATEMENT_DELIM_START,
    STATEMENT_DELIM_END,
    EXPRESSION_DELIM_START,
    EXPRESSION_DELIM_END,
    COMMENT_DELIM_START,
    COMMENT_DELIM_END,
    //
    STATEMENT,
    EXPRESSION,
    COMMENT,
    OTHER,
};

source: []const u8,
token_type: TokenType,
