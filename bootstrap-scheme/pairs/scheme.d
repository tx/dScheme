/*
 * Bootstrap Scheme - Strings
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_6-pairs
 * 
 */
import std.stdio;
import std.ascii;
import std.string;
import std.ctype;

/* Core data structures */

enum ObjectType {PAIR, EMPTY_LIST, STRING, CHARACTER, BOOLEAN, FIXNUM};

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
    struct {
      string* stringValue;
    };
    struct {
      Object* car;
      Object* cdr;
    };
  };
};

Object False;
Object True;
Object EmptyList;

/* Utility Functions */
bool isEmptyList(ref Object obj) {
  return obj == EmptyList;
}

bool isBoolean(ref Object obj){
  return obj.type == ObjectType.BOOLEAN;
}

bool isFalse(ref Object obj){
  return obj == False;
}

bool isTrue(ref Object obj){
  return !isFalse(obj);
}

bool isFixnum(ref Object obj){
  return obj.type == ObjectType.FIXNUM;
}

Object makeFixnum(long value){
  Object obj = Object(ObjectType.FIXNUM);
  obj.longValue = value;
  return obj;
}
bool isCharacter(ref Object obj){
  return obj.type == ObjectType.CHARACTER;
}

Object makeCharacter(char value){
  Object obj = Object(ObjectType.CHARACTER);
  obj.charValue = value;
  return obj;
}

Object makeString(string value){
  Object obj = Object(ObjectType.STRING);
  obj.stringValue = &value;
  return obj;
}

bool isString(ref Object obj){
  return obj.type == ObjectType.STRING;
}

Object cons(ref Object car, ref Object cdr){
  Object obj = Object(ObjectType.PAIR);
  obj.car = &car;
  obj.cdr = &cdr;
  return obj;
}

bool isPair(ref Object obj){
  return obj.type == ObjectType.PAIR;
}

pure Object* car(Object* pair){
  return pair.car;
}

void setCar(Object* obj, Object* value){
  obj.car = value;
}

pure Object* cdr(Object* pair){
  return pair.cdr;
}

void setCdr(Object* obj, Object* value){
  obj.cdr = value;
}

pure Object* caar(Object* obj){
  return car(car(obj));
}

pure Object* cadr(Object* obj){
  return car(cdr(obj));
}

pure Object* cdar(Object* obj){
  return cdr(car(obj));
}

pure Object* cddr(Object* obj){
  return cdr(cdr(obj));
}

pure Object* caaar(Object* obj){
  return car(car(car(obj)));
}

pure Object* caadr(Object* obj){
  return car(car(cdr(obj)));
}

pure Object* cadar(Object* obj){
  return car(cdr(car(obj)));
}

pure Object* caddr(Object* obj){
  return car(cdr(cdr(obj)));
}

pure Object* cdaar(Object* obj){
  return cdr(car(car(obj)));
}

pure Object* cdadr(Object* obj){
  return cdr(car(cdr(obj)));
}

pure Object* cddar(Object* obj){
  return cdr(cdr(car(obj)));
}

pure Object* cdddr(Object* obj){
  return cdr(cdr(cdr(obj)));
}

pure Object* caaaar(Object* obj){
  return car(car(car(car(obj))));
}

pure Object* caaadr(Object* obj){
  return car(car(car(cdr(obj))));
}

pure Object* caadar(Object* obj){
  return car(car(cdr(car(obj))));
}

pure Object* caaddr(Object* obj){
  return car(car(cdr(cdr(obj))));
}

pure Object* cadaar(Object* obj){
  return car(cdr(car(car(obj))));
}

pure Object* cadadr(Object* obj){
  return car(cdr(car(cdr(obj))));
}

pure Object* caddar(Object* obj){
  return car(cdr(cdr(car(obj))));
}

pure Object* cadddr(Object* obj){
  return car(cdr(cdr(cdr(obj))));
}

pure Object* cdaaar(Object* obj){
  return cdr(car(car(car(obj))));
}

pure Object* cdaadr(Object* obj){
  return cdr(car(car(cdr(obj))));
}

pure Object* cdadar(Object* obj){
  return cdr(car(cdr(car(obj))));
}

pure Object* cdaddr(Object* obj){
  return cdr(car(cdr(cdr(obj))));
}

pure Object* cddaar(Object* obj){
  return cdr(cdr(car(car(obj))));
}

pure Object* cddadr(Object* obj){
  return cdr(cdr(car(cdr(obj))));
}

pure Object* cdddar(Object* obj){
  return cdr(cdr(cdr(car(obj))));
}

pure Object* cddddr(Object* obj){
  return cdr(cdr(cdr(cdr(obj))));
}

void init(){
  EmptyList = Object(ObjectType.EMPTY_LIST);

  False = Object(ObjectType.BOOLEAN);
  False.boolValue = 0;

  True = Object(ObjectType.BOOLEAN);
  True.boolValue = 1;
}

/******************** READ ********************/

bool isDelimiter(char c){
  return isWhite(c) || c == EOF ||
         c == '('   || c== ')' || 
         c == '"'   || c == ';';
}

char peek(FILE* infile){
  int c;
  c = getc(infile);
  ungetc(c, infile);
  return cast(char) c;
}

void eatWhitespace(FILE* infile){
  int c;
  
  while ((c = getc(infile)) != EOF){
    if(isWhite(c)){ // ignore whitespace
      continue;
    } 
    else if (c == ';'){ // ignore comments
      while(((c = getc(infile)) != EOF) && (c != '\n')){};
      continue;
    }
    ungetc(c, infile);
    break;
  }
}

void peekExpectedDelimiter(FILE* infile){
  if(!isDelimiter(peek(infile))){
    throw new StdioException("character not followed by delimiter\n");
  }
}

void eatExpectedString(FILE* infile, string str){
  int c;
  foreach(ch; str){
    c = getc(infile);
    if(cast(char) c != ch){
      throw new StdioException("unexpected character '" ~ cast(char) c ~ "'\n");
    }
  }
}

Object readCharacter(FILE* infile){
  int c;

  c = getc(infile);
  switch(c){
  case EOF:
    throw new StdioException("incomplete character literal\n");
  case 's':
    if(peek(infile) == 'p'){
      eatExpectedString(infile, "pace");
      peekExpectedDelimiter(infile);
      return makeCharacter(' ');
    }
    break;
  case 'n':
    if(peek(infile) == 'e'){
		eatExpectedString(infile, "ewline");
		peekExpectedDelimiter(infile);
		return makeCharacter('\n');
	}
    break;
  default:
  	break;    
  }
  peekExpectedDelimiter(infile);
  return makeCharacter(cast(char) c);
}

Object readPair(FILE* infile) {
  int c;
  Object car_obj;
  Object cdr_obj;

  eatWhitespace(infile);

  c = getc(infile);
  if(c == ')') { // Read the emtpy list
    return EmptyList;
  }
  ungetc(c, infile);

  car_obj = read(infile);
  eatWhitespace(infile);
  
  c = getc(infile);
  if(c == ',') { //improper list
    c = peek(infile);
    if(!isDelimiter(cast(char) c)){
      throw new StdioException("dot not follwed by delimiter\n");
    }
    cdr_obj = read(infile);
    eatWhitespace(infile);
    c = getc(infile);
    if( c!= ')') {
      throw new StdioException("missing right paren.\n");
    }
    return cons(car_obj, cdr_obj);
  }
  else { // read list
    ungetc(c, infile);
    cdr_obj = readPair(infile);
    return cons(car_obj, cdr_obj);
  }
}

Object read(FILE* infile){
  int c;
  short sign = 1;
  long num = 0;
  char[] buffer;
  const int INITIAL_ARR_SIZE = 1000;

  eatWhitespace(infile);
  
  c = getc(infile);

  if(c == '#'){ //boolean literal
    c = getc(infile);
    switch(c){
    case 't':
      return True;
    case 'f':
      return False;
    case '\\':
      return readCharacter(infile);
    default:
      throw new StdioException("unknown boolean literal\n");
    }
  } 
  else if(isDigit(c) || (c == '-' && (isDigit(peek(infile))))){
    // Fix num
    if(c == '-'){
      sign = -1;
    } 
    else {
      ungetc(c, infile);
    }
    while(isDigit(c = getc(infile))){
      num = (num * 10) + (c - '0');
    }
    num *= sign;
    if(isDelimiter(cast(char) c)){
      ungetc(c, infile);
      return makeFixnum(num);
    } 
    else {
      throw new StdioException("number not followed by delimiter\n");
    }
  } 
  else if(cast(char) c  == '"'){ /* read a string */
    auto i = 0;
    buffer.length = INITIAL_ARR_SIZE;
    while((c = getc(infile)) != '"'){
      if(c == '\\'){
	c = getc(infile);
	if(c == 'n'){
	  c = '\n';
	}
      }
      if(c == EOF){
	throw new StdioException("non-terminated string literal\n");
      }
      if(i == buffer.length)
	buffer.length *= 2;
      buffer[i] = cast(char) c;
      i++;
    }
    buffer.length = i;
    return makeString(buffer.idup);
  } 
  else if(c == '('){
    return readPair(infile);
  } 
  else {
      throw new StdioException("unexpected character '" 
			       ~ cast(char) c 
			       ~ "'. Expecting ')'\n");
  }
} 


/********************* EVALUATE *********************/

/* just echo for now */
Object eval(Object exp){
  return exp;
}

/********************* PRINT *********************/

void write(Object obj){
  switch(obj.type){
  case ObjectType.EMPTY_LIST:
    printf("()");
    break;
  case ObjectType.BOOLEAN:
    printf("#%c", isFalse(obj) ? 'f' : 't');
    break;
  case ObjectType.FIXNUM:
    printf("%ld", obj.longValue);
    break;
  case ObjectType.CHARACTER:
    printf("#\\");
    switch(obj.charValue){
    case '\n':
      printf("newline");
      break;
    case ' ':
      printf("space");
      break;
    default:
      putchar(obj.charValue);
    }
    break;
  case ObjectType.STRING:
    string str = *obj.stringValue;
    putchar('"');
    foreach(ch; str){
      switch(ch){
      case '\n':
	printf("\\n");
	break;
      case '\\':
	printf("\\\\");
	break;
      case '"':
	printf("\\\"");
	break;
      default:
	putchar(ch);
      }
    }
    putchar('"');
    break;
  default:
    throw new StdioException("cannot write unknown type\n");
  }
}

/********************* REPL *********************/

int main(char[][] args){
  printf("Welcome to Bootstrap Scheme. User Ctrl-C to exit.\n");

  init();

  while(true){
    printf("> ");
    write(eval(read(stdin.getFP())));
    printf("\n");
  }
  return 0;
}