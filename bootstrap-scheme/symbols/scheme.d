/*
 * Bootstrap Scheme - Symbols
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_7-symbols
 * 
 */
import std.stdio;
import std.ascii;
import std.string;
import std.ctype;

/* Core data structures */

enum ObjectType {PAIR, EMPTY_LIST, STRING, CHARACTER, BOOLEAN, SYMBOL, FIXNUM};
class Obj {
  public const ObjectType type;

  this(ObjectType type) {
    this.type = type;
  }

  ObjectType getType() {
    return type;
  }
}

class Boolean : Obj {
  public const bool value;
  this(bool b){
    value = b;
    super(ObjectType.BOOLEAN);
  }
}

class Number : Obj {
  public const long value;
  this(long l){
    value = l;
    super(ObjectType.FIXNUM);
  }
}

class Character : Obj {
  public const char value;
  this(char c){
    value = c;
    super(ObjectType.CHARACTER);
  }
}

class String : Obj {
  public const string value;
  this(string s){
    value = s;
    super(ObjectType.STRING);
  }
}

class Pair : Obj {
  public Obj car;
  public Obj cdr;
  this(Obj carObj, Obj cdrObj){
    car = carObj;
    cdr = cdrObj;
    super(ObjectType.PAIR);
  }
}

class Symbol : Obj {
  public const string value;
  this(string s){
    value = s;
    super(ObjectType.SYMBOL);
  }
}

Obj False;
Obj True; 
Obj EmptyList;
Symbol[string] SymbolTable;

void init(){
  EmptyList = new Obj(ObjectType.EMPTY_LIST);
  False = new Boolean(false);
  True = new Boolean(true);
}


/* Utility Functions */
bool isEmptyList(ref Obj obj) {
  return obj == EmptyList;
}

bool isBoolean(ref Obj obj){
  return obj.type == ObjectType.BOOLEAN;
}

bool isFalse(ref Obj obj){
  return obj == False;
}

bool isTrue(ref Obj obj){
  return !isFalse(obj);
}

bool isFixnum(ref Obj obj){
  return obj.type == ObjectType.FIXNUM;
}

Number makeFixnum(long value){
  Number obj = new Number(value);
  return obj;
}

bool isCharacter(ref Obj obj){
  return obj.type == ObjectType.CHARACTER;
}

Character makeCharacter(char value){
  Character obj = new Character(value);
  return obj;
}

String makeString(string value){
  String obj = new String(value);
  return obj;
}

bool isString(ref Obj obj){
  return obj.type == ObjectType.STRING;
}

Pair cons(Obj car, Obj cdr){
  Pair obj = new Pair(car, cdr);
  return obj;
}

bool isPair(ref Obj obj){
  return obj.type == ObjectType.PAIR;
}

pure Obj car(ref Obj pair){
  return (cast(Pair) pair).car;
}

void setCar(Pair* obj, Obj value){
  obj.car = value;
}

pure Obj cdr(ref Obj pair){
  return (cast(Pair) pair).cdr;
}

void setCdr(Pair* obj, Obj value){
  obj.cdr = value;
}

bool isSymbol(Obj obj){
  return obj.type == ObjectType.SYMBOL;
}

Obj makeSymbol(string value){
  Symbol* obj;
  obj = (value in SymbolTable);
  if(obj != null){
    return *obj;
  }
  Symbol symbol = new Symbol(value);
  SymbolTable[value] = symbol;
  return symbol;
  
}

/******************** READ ********************/

bool isDelimiter(char c){
  return isWhite(c) || c == EOF ||
         c == '('   || c== ')' || 
         c == '"'   || c == ';';
}

bool isInitial(char c) {
    return isAlpha(c) || c == '*' ||
      c == '/' || c == '>' ||
      c == '<' || c == '=' || 
      c == '?' || c == '!';
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
      while(((c = getc(infile)) != EOF) && (c != '\n')){ }
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

Obj readCharacter(FILE* infile){
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

Obj readPair(FILE* infile) {
  int c;
  Obj car_obj;
  Obj cdr_obj;

  eatWhitespace(infile);

  c = getc(infile);
  if(c == ')') { // Read the emtpy list
    return EmptyList;
  }
  ungetc(c, infile);

  car_obj = read(infile);
  eatWhitespace(infile);
  
  c = getc(infile);
  if(c == '.') { //improper list
    c = peek(infile);
    if(!isDelimiter(cast(char) c)){
      throw new StdioException("dot not follwed by delimiter\n");
    }
    cdr_obj = read(infile);
    eatWhitespace(infile);
    c = getc(infile);
    if(c != ')') {
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

Obj read(FILE* infile){
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
  } else if(isInitial(cast(char) c) || 
	    ((c == '+' || c == '-') && 
	     isDelimiter(peek(infile)))) { // read a symbol
    auto i = 0;
    buffer.length = INITIAL_ARR_SIZE;
    while(isInitial(cast(char) c) || isDigit(cast(char) c) || c == '+' || c == '-') {
      if(i >= INITIAL_ARR_SIZE){
	throw new StdioException("symbol too long.");
      }
      buffer[i] = cast(char) c;
      c = getc(infile);
      i++;
    }
    if(isDelimiter(cast(char) c)) {
      ungetc(c, infile);
      return makeSymbol(buffer[0..i].idup);
    } else {
      throw new StdioException("symbol not followed by delimiter. Found '%c'\n", c);
    }
  } else if(cast(char) c  == '"'){ /* read a string */
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
  else if(cast(char) c == '('){
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
Obj eval(Obj exp){
  return exp;
}

/********************* PRINT *********************/

void writePair(ref Obj pair){
  Obj car_obj = car(pair);
  Obj cdr_obj = cdr(pair);

  write(car_obj);
  if(cdr_obj.type == ObjectType.PAIR) {
    printf(" ");
    write(cdr_obj);
  }
  else if(cdr_obj.type == ObjectType.EMPTY_LIST){
    printf(" () ");
    return;
  }
  else {
    printf(" . ");
    write(cdr_obj);
  }
}

void write(Obj obj){
  switch(obj.type){
  case ObjectType.EMPTY_LIST:
    printf("()");
    break;
  case ObjectType.BOOLEAN:
    printf("#%c", isFalse(obj) ? 'f' : 't');
    break;
  case ObjectType.FIXNUM:
    printf("%ld", (cast(Number) obj).value);
    break;
  case ObjectType.CHARACTER:
    printf("#\\");
    switch((cast(Character) obj).value){
    case '\n':
      printf("newline");
      break;
    case ' ':
      printf("space");
      break;
    default:
      putchar((cast(Character) obj).value);
    }
    break;
  case ObjectType.STRING:
    string str = (cast(String) obj).value;
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
  case ObjectType.PAIR:
    printf("(");
    writePair(obj);
    printf(")");
    break;
  case ObjectType.SYMBOL:
    writef("%s", (cast(Symbol) obj).value);
    break;
  default:
    throw new StdioException("cannot write unknown type\n");
  }
}

/********************* REPL *********************/


int main(char[][] args){

  printf("Welcome to Bootstrap Scheme. Use Ctrl-C to exit.\n");

    init();

  while(true){
    printf("> ");
    try {
      write(eval(read(stdin.getFP())));
    } catch (Exception e){
      writef("ERROR: %s", e.msg);
    }
    printf("\n");
  }
  return 0;
}