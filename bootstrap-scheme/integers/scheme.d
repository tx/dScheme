/*
 * Bootstrap Scheme - Integers
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_1-integers
 * 
 */
import std.stdio;
import std.ascii;

enum ObjectType {FIXNUM}

struct Object {
  ObjectType type;

  union {
    struct {
      long value;
    }
  };

  this(ObjectType t){
    this.type = t;
  }
}

Object make_fixnum(long value){
  Object obj = Object(ObjectType.FIXNUM);
  obj.value = value;
  return obj;
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
      while(((c = getc(infile)) != EOF) && (c != '\n')){};
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

  if(isDigit(c) || (c == '=' && (isDigit(peek(infile))))) {
    if(c == '-') {
      sign = -1;
    }
    else {
      ungetc(c, infile);
    }
    while(isDigit(c = getc(infile))) {
      num = (num * 10) + (c - '0');
    }
    num *= sign;
    if(isDelimiter(cast(char) c)) {
      ungetc(c, infile);
      return make_fixnum(num);
    }
    else {
      throw new StdioException("number not followed by delimiter\n");
    }
  }
  else {
    throw new StdioException("bad input. Unexpected character\n");
  }
  throw new StdioException("read illegal state\n");
}


/********************* EVALUATE *********************/

/* just echo for now */
Object eval(Object exp) {
  return exp;
}

/********************* PRINT *********************/

void write(Object obj) {
  switch(obj.type){
  case ObjectType.FIXNUM:
    printf("%ld", obj.value);
    break;
  default:
    throw new StdioException("cannot write unknown type\n");
  }
}

/********************* REPL *********************/

int main(char[][] args) {
  printf("Welcome to Bootstrap Scheme. User Ctrl-C to exit.\n");
  
  while(true) {
    printf("> ");
    write(eval(read(stdin.getFP())));
    printf("\n");
  }
  return 0;
}