/*
 * Bootstrap Scheme - If
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_10-if
 * 
 */
import std.stdio;
import std.ascii;
import std.string;
import std.ctype;

/* Core data structures */

enum ObjectType {PAIR, EMPTY_LIST, STRING, CHARACTER, BOOLEAN, SYMBOL, FIXNUM};
class Obj : Object {
  public const ObjectType type;
  this(ObjectType type) {
    this.type = type;
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
  public const string value;
  this(Obj carObj, Obj cdrObj){
    car = carObj;
    cdr = cdrObj;
    value = "[Pair]";
    super(ObjectType.PAIR);
  }
}

class Symbol : Obj {
  public const string value;
  this(string s){
    value = s;
    super(ObjectType.SYMBOL);
  }

  override public bool opEquals(Object o){
    if(cast(Symbol) o is null)
      return false;
    return this.value == (cast(Symbol) o).value;
  }
}

Boolean False;
Boolean True; 
Obj EmptyList;
Obj EmptyEnvironment;
Pair GlobalEnvironment;
Symbol Quote;
Symbol Ok;
Symbol Set;
Symbol Define;
Symbol If;
Symbol[string] SymbolTable;

void init(){
  EmptyList = new Obj(ObjectType.EMPTY_LIST);
  False = new Boolean(false);
  True = new Boolean(true);
  Quote = new Symbol("quote");
  Define = new Symbol("define");
  Set = new Symbol("set!");
  Ok = new Symbol("ok");
  If = new Symbol("if");
  EmptyEnvironment = EmptyList;
  GlobalEnvironment = setupEnvironment();
}


/* Utility Functions */
bool isEmptyList(Obj obj) {
  return obj == EmptyList;
}

pure bool isBoolean(Obj obj){
  return obj.type == ObjectType.BOOLEAN;
}

bool isFalse(Obj obj){
  return obj == False;
}

bool isTrue(Obj obj){
  return !isFalse(obj);
}

pure bool isFixnum(Obj obj){
  return obj.type == ObjectType.FIXNUM;
}

Number makeFixnum(long value){
  Number obj = new Number(value);
  return obj;
}

pure bool isCharacter(Obj obj){
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

pure bool isString(Obj obj){
  return obj.type == ObjectType.STRING;
}

Pair cons(Obj car, Obj cdr){
  Pair obj = new Pair(car, cdr);
  return obj;
}

pure bool isPair(Obj obj){
  return obj.type == ObjectType.PAIR;
}

pure Obj car(Obj obj){
  return isPair(obj) ? (cast(Pair) obj).car : obj;
}

pure Obj cdr(Obj obj){
  return isPair(obj) ? (cast(Pair) obj).cdr : obj;
}

pure Obj caar(Pair obj){ return car(car(obj)); }
pure Obj cadr(Pair obj){ return car(cdr(obj)); }
pure Obj cdar(Pair obj){ return cdr(car(obj)); }
pure Obj cddr(Pair obj){ return cdr(cdr(obj)); }
pure Obj caaar(Pair obj){ return car(car(car(obj))); }
pure Obj caadr(Pair obj){ return car(car(cdr(obj))); }
pure Obj cadar(Pair obj){ return car(cdr(car(obj))); }
pure Obj caddr(Pair obj){ return car(cdr(cdr(obj))); }
pure Obj cdaar(Pair obj){ return cdr(car(car(obj))); }
pure Obj cdadr(Pair obj){ return cdr(car(cdr(obj))); }
pure Obj cddar(Pair obj){ return cdr(cdr(car(obj))); }
pure Obj cdddr(Pair obj){ return cdr(cdr(cdr(obj))); }
pure Obj caaaar(Pair obj){ return car(car(car(car(obj)))); }
pure Obj caaadr(Pair obj){ return car(car(car(cdr(obj)))); }
pure Obj caadar(Pair obj){ return car(car(cdr(car(obj)))); }
pure Obj caaddr(Pair obj){ return car(car(cdr(cdr(obj)))); }
pure Obj cadaar(Pair obj){ return car(cdr(car(car(obj)))); }
pure Obj cadadr(Pair obj){ return car(cdr(car(cdr(obj)))); }
pure Obj caddar(Pair obj){ return car(cdr(cdr(car(obj)))); }
pure Obj cadddr(Pair obj){ return car(cdr(cdr(cdr(obj)))); }
pure Obj cdaaar(Pair obj){ return cdr(car(car(car(obj)))); }
pure Obj cdaadr(Pair obj){ return cdr(car(car(cdr(obj)))); }
pure Obj cdadar(Pair obj){ return cdr(car(cdr(car(obj)))); }
pure Obj cdaddr(Pair obj){ return cdr(car(cdr(cdr(obj)))); }
pure Obj cddaar(Pair obj){ return cdr(cdr(car(car(obj)))); }
pure Obj cddadr(Pair obj){ return cdr(cdr(car(cdr(obj)))); }
pure Obj cdddar(Pair obj){ return cdr(cdr(cdr(car(obj)))); }
pure Obj cddddr(Pair obj){ return cdr(cdr(cdr(cdr(obj)))); }

Obj enclosingEnvironment(Obj env){
  return cdr(env);
}

Obj firstFrame(Obj env){
  return car(env);
}

Pair makeFrame(Obj variables, Obj values){
  return cons(variables, values);
}

Obj frameVariables(Pair frame) {
  return car(frame);
}

Obj frameValues(Pair frame) {
  return cdr(frame);
}

void addBindingToFrame(Obj var, Obj val, Pair frame){
  setCar(frame, cons(var, car(frame)));
  setCdr(frame, cons(val, cdr(frame)));
}

Pair extendEnvironcment(Obj vars, Obj vals, Obj baseEnv) {
  return cons(makeFrame(vars, vals), baseEnv);
}

Obj lookupVariableValue(Obj var, Obj env) {
  Pair frame;
  Obj vars;
  Obj vals;
  while(!isEmptyList(env)){
    frame = cast(Pair) firstFrame(env);
    vars = frameVariables(frame);
    vals = frameValues(frame);
    while(!isEmptyList(vars)) {
      if(var == car(vars)) {
	return car(vals);
      }
      vars = cdr(vars);
      vals = cdr(vals);
    }
    env = enclosingEnvironment(env);
  }
  throw new StdioException("unbound variable.");
}

Obj setVariableValue(Obj var, Obj val, Obj env) {
  Pair frame;
  Obj vars;
  Obj vals;
  while(!isEmptyList(env)){
    frame = cast(Pair) firstFrame(env);
    vars = frameVariables(frame);
    vals = frameValues(frame);
    while(!isEmptyList(vars)) {
      if(var == car(vars)) {
	(cast(Pair) vals).car = val;
	return val;
      }
      vars = cdr(vars);
      vals = cdr(vals);
    }
    env = enclosingEnvironment(env);
  }
  throw new StdioException("unbound variable.");
}

Obj defineVariable(Obj var, Obj val, Obj env){
  Pair frame = cast(Pair) firstFrame(env);
  Obj vars = frameVariables(frame);
  Obj vals = frameValues(frame);
  while(!isEmptyList(vars)) {
    if(var == car(vars)) {
      (cast(Pair) vals).car = val;
      return val;
    }
    vars = cdr(vars);
    vals = cdr(vals);
  }
  addBindingToFrame(var, val, frame);
  return val;
}

Pair setupEnvironment(){
  return extendEnvironment(EmptyList, EmptyList, EmptyEnvironment);
}

void setCar(Pair obj, Obj value){
  obj.car = value;
}

void setCdr(Pair obj, Obj value){
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
  } else if(cast(char) c == '('){ // empty list or pair
    return readPair(infile);
  } else if (cast(char) c == '\'') { // quoted expression
    return cons(Quote, cons(read(infile), EmptyList));
  } else {
    throw new StdioException("unexpected character '" 
			     ~ cast(char) c ~ "'");
  }
} 


/********************* EVALUATE *********************/
pure bool isSelfEvaluating(Obj obj){
  return isBoolean(obj) 
    || isFixnum(obj) 
    || isCharacter(obj) 
    || isString(obj);
}
bool isVariable(Obj expression) {
  return isSymbol(expression);
}


bool isTaggedList(Obj expression, Symbol tag){
  Obj car_obj;
  if(isPair(expression)) {
    car_obj = car(expression);
    return isSymbol(car_obj) && tag == car_obj;
  }
  return false;
}

bool isQuoted(Obj expression) {
  return isTaggedList(expression, Quote);
}

Obj textOfQuotation(Pair exp) {
  return cadr(exp);
}

bool isAssignment(Obj exp) {
  return isTaggedList(exp, Set);
}

Obj assignmentVariable(Obj exp){
  return car(cdr(exp));
}

Obj assignmentValue(Obj exp){
  return car(cdr(cdr(exp)));
}

bool isDefinition(Obj exp){
  return isTaggedList(exp, Define);
}

Obj definitionVariable(Pair exp) {
  return cadr(exp);
}

Obj definitionValue(Pair exp) {
  return caddr(exp);
}

bool isIf(Obj exp) {
  return isTaggedList(exp, If);
}

Obj Predicate(Pair exp) {
  return cadr(exp);
}

Obj Consequent(Pair exp) {
  return caddr(exp);
}

Obj Alternative(Pair exp) {
    if(isEmptyList(cdddr(exp))) {
      return False;
    }
    else {
      return cadddr(exp);
    }
}

Obj evalAssignment(Obj exp, Obj env) {
  return setVariableValue(assignmentVariable(exp),
		   eval(assignmentValue(exp), env),
		   env);
}

Obj evalDefinition(Pair exp, Pair env) {
  return defineVariable(definitionVariable(exp),
			eval(definitionValue(exp), env),
			env);
}
/* just echo for now */
Obj eval(Obj exp, Obj env){
  while(true) {
      if(isSelfEvaluating(exp)) {
	  return exp;
      } else if(isVariable(exp)) {
	  return lookupVariableValue(exp, env);
      } else if(isQuoted(exp)) {
	  return textOfQuotation(cast(Pair) exp);
      } else if(isAssignment(exp)){
	  return evalAssignment(exp, env);
      } else if(isDefinition(exp)){
	  return evalDefinition(cast(Pair) exp, cast(Pair) env);
      } else if(isIf(exp)) {
	  if(isTrue(eval(Predicate(cast(Pair) exp), env))){
	      exp = Consequent(cast(Pair) exp);
	  }
	  else {
	      exp = Alternative(cast(Pair) exp);
	  }
      } else {
	  throw new StdioException("Cannot eval unknown expression type.");
      }
      //      throw new StdioException("Illegal evaluation state!");
  }
}

/********************* PRINT *********************/

void writePair(Obj pair){
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
c  switch(obj.type){
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
      write(eval(read(stdin.getFP()), GlobalEnvironment));
    } catch (Exception e){
      writef("ERROR: %s", e.msg);
    }
    printf("\n");
  }
  return 0;
}
