/*
 * Bootstrap Scheme - Quote
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_8-quote
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
Symbol QuoteSymbol;
Symbol[string] SymbolTable;

void init(){
  EmptyList = new Obj(ObjectType.EMPTY_LIST);
  False = new Boolean(false);
  True = new Boolean(true);
  QuoteSymbol = new Symbol("quote");
}


/* Utility Functions */
bool isEmptyList(ref Obj obj) {
  return obj == EmptyList;
}

pure bool isBoolean(ref Obj obj){
  return obj.type == ObjectType.BOOLEAN;
}

bool isFalse(ref Obj obj){
  return obj == False;
}

bool isTrue(ref Obj obj){
  return !isFalse(obj);
}

pure bool isFixnum(ref Obj obj){
  return obj.type == ObjectType.FIXNUM;
}

Number makeFixnum(long value){
  Number obj = new Number(value);
  return obj;
}

pure bool isCharacter(ref Obj obj){
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

pure bool isString(ref Obj obj){
  return obj.type == ObjectType.STRING;
}

Pair cons(Obj car, Obj cdr){
  Pair obj = new Pair(car, cdr);
  return obj;
}

pure bool isPair(ref Obj obj){
  return obj.type == ObjectType.PAIR;
}

pure Obj car(Obj obj){
  return isPair(obj) ? (cast(Pair) obj).car : obj;
}

pure Obj cdr(Obj obj){
  return isPair(obj) ? (cast(Pair) obj).cdr : obj;
}

pure Obj caar(ref Obj obj){ return car(car(obj)); }
pure Obj cadr(ref Obj obj){ return car(cdr(obj)); }
pure Obj cdar(ref Obj obj){ return cdr(car(obj)); }
pure Obj cddr(ref Obj obj){ return cdr(cdr(obj)); }
pure Obj caaar(ref Obj obj){ return car(car(car(obj))); }
pure Obj caadr(ref Obj obj){ return car(car(cdr(obj))); }
pure Obj cadar(ref Obj obj){ return car(cdr(car(obj))); }
pure Obj caddr(ref Obj obj){ return car(cdr(cdr(obj))); }
pure Obj cdaar(ref Obj obj){ return cdr(car(car(obj))); }
pure Obj cdadr(ref Obj obj){ return cdr(car(cdr(obj))); }
pure Obj cddar(ref Obj obj){ return cdr(cdr(car(obj))); }
pure Obj cdddr(ref Obj obj){ return cdr(cdr(cdr(obj))); }
pure Obj caaaar(ref Obj obj){ return car(car(car(car(obj)))); }
pure Obj caaadr(ref Obj obj){ return car(car(car(cdr(obj)))); }
pure Obj caadar(ref Obj obj){ return car(car(cdr(car(obj)))); }
pure Obj caaddr(ref Obj obj){ return car(car(cdr(cdr(obj)))); }
pure Obj cadaar(ref Obj obj){ return car(cdr(car(car(obj)))); }
pure Obj cadadr(ref Obj obj){ return car(cdr(car(cdr(obj)))); }
pure Obj caddar(ref Obj obj){ return car(cdr(cdr(car(obj)))); }
pure Obj cadddr(ref Obj obj){ return car(cdr(cdr(cdr(obj)))); }
pure Obj cdaaar(ref Obj obj){ return cdr(car(car(car(obj)))); }
pure Obj cdaadr(ref Obj obj){ return cdr(car(car(cdr(obj)))); }
pure Obj cdadar(ref Obj obj){ return cdr(car(cdr(car(obj)))); }
pure Obj cdaddr(ref Obj obj){ return cdr(car(cdr(cdr(obj)))); }
pure Obj cddaar(ref Obj obj){ return cdr(cdr(car(car(obj)))); }
pure Obj cddadr(ref Obj obj){ return cdr(cdr(car(cdr(obj)))); }
pure Obj cdddar(ref Obj obj){ return cdr(cdr(cdr(car(obj)))); }
pure Obj cddddr(ref Obj obj){ return cdr(cdr(cdr(cdr(obj)))); }

void setCar(Pair* obj, Obj value){
  obj.car = value;
}

void setCdr(Pair* obj, Obj value){
  obj.cdr = value;
}

pure bool isSymbol(Obj obj){
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

pure bool isDelimiter(char c){
  return isWhite(c) 
    || c == EOF 
    || c == '('   
    || c == ')' 
    || c == '"'   
    || c == ';';
}

pure bool isInitial(char c) {
    return isAlpha(c) 
      || c == '*' 
      || c == '/' 
      || c == '>' 
      || c == '<' 
      || c == '=' 
      || c == '?' 
      || c == '!';
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
    throw new StdioException("character not followed by delimiter.");
  }
}

void eatExpectedString(FILE* infile, string str){
  int c;
  foreach(ch; str){
    c = getc(infile);
    if(cast(char) c != ch){
      throw new StdioException("unexpected character '" ~ cast(char) c ~ "'.");
    }
  }
}

Obj readCharacter(FILE* infile){
  int c;

  c = getc(infile);
  switch(c){
  case EOF:
    throw new StdioException("incomplete character literal.");
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
      throw new StdioException("dot not follwed by delimiter.");
    }
    cdr_obj = read(infile);
    eatWhitespace(infile);
    c = getc(infile);
    if(c != ')') {
      throw new StdioException("missing right paren.");
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
      throw new StdioException("unknown boolean literal.");
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
      throw new StdioException("number not followed by delimiter.");
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
      throw new StdioException("symbol not followed by delimiter. Found '%c'.", c);
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
	throw new StdioException("non-terminated string literal.");
      }
      if(i == buffer.length)
	buffer.length *= 2;
      buffer[i] = cast(char) c;
      i++;
    }
    buffer.length = i;
    return makeString(buffer.idup);
  } else if(cast(char) c == '('){
    return readPair(infile);
  } else if (cast(char) c == '\'') { 
    return cons(QuoteSymbol, cons(read(infile), EmptyList));
  } else {
    throw new StdioException("unexpected character '" 
			     ~ cast(char) c ~ "'");
  }
} 


/********************* EVALUATE *********************/
pure bool isSelfEvaluating(ref Obj obj){
  return isBoolean(obj) 
    || isFixnum(obj) 
    || isCharacter(obj) 
    || isString(obj);
}

bool isTaggedList(Obj expression, Obj tag){
  Obj car_obj;
  if(isPair(expression)) {
    car_obj = car(expression);
    return isSymbol(car_obj) && (car_obj == tag);
  }
  return false;
}

bool isQuoted(ref Obj expression) {
  return isTaggedList(expression, QuoteSymbol);
}

Obj textOfQuotation(ref Obj exp) {
  return cadr(exp);
}

/* just echo for now */
Obj eval(Obj exp){
  if(isSelfEvaluating(exp)) {
    return exp;
  } else if(isQuoted(exp)) {
    return textOfQuotation(exp);
  } else {
    throw new StdioException("Cannot eval unknown expression type.");
  }
  throw new StdioException("Illegal evaluation state!");
}

/********************* PRINT *********************/

void writePair(ref Obj pair){
  Obj car_obj = car(pair);
  Obj cdr_obj = cdr(pair);

  write(car_obj);
  if(cdr_obj.type == ObjectType.PAIR) {
    printf(" ");
    writePair(cdr_obj);
  }
  else if(cdr_obj.type == ObjectType.EMPTY_LIST){
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
    throw new StdioException("cannot write unknown type.");
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
