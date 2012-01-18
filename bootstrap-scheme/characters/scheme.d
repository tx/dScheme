/*
 * Bootstrap Scheme - Characters
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_3-characters
 * 
 */
import std.stdio;
import std.ascii;
import std.string;
import std.ctype;

/* Core data structures */

enum ObjectType {CHARACTER, BOOLEAN, FIXNUM};

struct Object {
  ObjectType type;

  union {
    struct {
      long longValue;
    };
    struct {
      char boolValue;
    };
    struct {
      char charValue;
    };
  };
};

Object False;
Object True;

/* Utility Functions */

char isBoolean(Object obj) {
  return obj.type == ObjectType.BOOLEAN;
}

char isFalse(Object obj) {
  return obj == False;
}

char isTrue(Object obj) {
  return !isFalse(obj);
}

char isFixnum(Object obj) {
  return obj.type == ObjectType.FIXNUM;
}

Object makeFixnum(long value) {
  Object obj = Object(ObjectType.FIXNUM);
  obj.longValue = value;
  return obj;
}
char isCharacter(Object obj) {
  return obj.type == ObjectType.CHARACTER;
}

Object makeCharacter(char value) {
  Object obj = Object(ObjectType.CHARACTER);
  obj.charValue = value;
  return obj;
}

void init() {
  False = Object(ObjectType.BOOLEAN);
  False.boolValue = 0;

  True = Object(ObjectType.BOOLEAN);
  True.boolValue = 1;
}

/******************** READ ********************/

char isDelimiter(char c) {
  return isWhite(c) || c == EOF ||
         c == '('   || c== ')' || 
         c == '"'   || c == ';';
}

char peek(FILE* infile) {
  int c;
  c = getc(infile);
  ungetc(c, infile);
  return cast(char) c;
}

void eatWhitespace(FILE* infile) {
  int c;
  
  while ((c = getc(infile)) != EOF) {
    if(isWhite(c)) { // ignore whitespace
      continue;
    } 
    else if (c == ';') { // ignore comments
      while(((c = getc(infile)) != EOF) && (c != '\n')) {};
      continue;
    }
    ungetc(c, infile);
    break;
  }
}

Object readCharacter(FILE* infile) {
  int c;

  c = getc(infile);
  switch(c) {
  case EOF:
    throw new StdioException("incomplete character literal\n");
  case 's':
    if(peek(infile) == 'p') {
      eatExpectedString(infile, "pace");
      //TODO line 169 in original source
    }
    break;
  default:
    printf("default");
  }
}

void eatExpectedString(FILE* infile, char* str) {
  int c;

  while(str != '\0') {
    c = getc(infile);
    if(c != str) {
      throw new StdioException("unexpected character '%c'\n", c);
    }
    str++;
  }
}
void eatWhitespace(FILE* infile) {
  int c;

  while((c = getc(infile)) != EOF) {
    if(isSpace(c)) {
      continue;
    } else if(c == ';') { //comments are whitespace too
      while(((c = getc(infile)) != EOF) && (c != '\n')) {};
      continue;
    }
    ungetc(c, infile);
    break;
  }
}

Object read(FILE* infile) {
  int c;
  short sign = 1;
  long num = 0;

  eatWhitespace(infile);
  
  c = getc(infile);
  if(c == '#') { //boolean literal
    c = getc(infile);
    switch(c) {
    case 't':
      return True;
    case 'f':
      return False;
    default:
      throw new StdioException("unknown boolean literal\n");
    }
  } else if(isDigit(c) || (c == '-' && (isDigit(peek(infile))))) {
    // Fix num
    if(c == '-') {
      sign = -1;
    } else {
      ungetc(c, infile);
    }
    while(isDigit(c = getc(infile))) {
      num = (num * 10) + (c - '0');
    }
    num *= sign;
    if(isDelimiter(cast(char) c)) {
      ungetc(c, infile);
      return makeFixnum(num);
    } else {
      throw new StdioException("number not followed by delimiter\n");
    }
  }
  else {
    throw new StdioException("bad input. Unexpected character\n");
  }
}


/********************* EVALUATE *********************/

/* just echo for now */
Object eval(Object exp) {
  return exp;
}

/********************* PRINT *********************/

void write(Object obj) {
  switch(obj.type) {
  case ObjectType.BOOLEAN:
    printf("#%c", isFalse(obj) ? 'f' : 't');
    break;
  case ObjectType.FIXNUM:
    printf("%ld", obj.longValue);
    break;
  case ObjectType.CHARACTER:
    printf("#\\");
    switch(c) {
    case '\n':
      printf("newline");
      break;
    case ' ':
      printf("space");
      break;
    default:
      putchar(c);
    }
    break;
  default:
    throw new StdioException("cannot write unknown type\n");
  }
}

/********************* REPL *********************/

int main(char[][] args) {
  printf("Welcome to Bootstrap Scheme. User Ctrl-C to exit.\n");

  init();

  while(true) {
    printf("> ");
    write(eval(read(stdin.getFP())));
    printf("\n");
  }
  return 0;
}