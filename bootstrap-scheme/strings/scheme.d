/*
 * Bootstrap Scheme - Strings
 * A D implementation of the tutorial housed at 
 * http://michaux.ca/articles/scheme-from-scratch-bootstrap-v0_4-strings
 * 
 */
import std.stdio;
import std.ascii;
import std.string;
import std.ctype;

/* Core data structures */

enum ObjectType {STRING, CHARACTER, BOOLEAN, FIXNUM};

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
      string stringValue;
    };
  };
};

Object False;
Object True;

/* Utility Functions */

char isBoolean(Object obj){
  return obj.type == ObjectType.BOOLEAN;
}

char isFalse(Object obj){
  return obj == False;
}

char isTrue(Object obj){
  return !isFalse(obj);
}

char isFixnum(Object obj){
  return obj.type == ObjectType.FIXNUM;
}

Object makeFixnum(long value){
  Object obj = Object(ObjectType.FIXNUM);
  obj.longValue = value;
  return obj;
}
char isCharacter(Object obj){
  return obj.type == ObjectType.CHARACTER;
}

Object makeCharacter(char value){
  Object obj = Object(ObjectType.CHARACTER);
  obj.charValue = value;
  return obj;
}

Object makeString(string value){
  Object obj = Object(ObjectType.STRING);
  obj.stringValue = value;
  return obj;
}

char isString(Object obj){
  return obj.type == ObjectType.STRING;
}

void init(){
  False = Object(ObjectType.BOOLEAN);
  False.boolValue = 0;

  True = Object(ObjectType.BOOLEAN);
  True.boolValue = 1;
}

/******************** READ ********************/

char isDelimiter(char c){
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
      throw new StdioException("unexpected character '%c'\n", c);
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
  } else if(isDigit(c) || (c == '-' && (isDigit(peek(infile))))){
    // Fix num
    if(c == '-'){
      sign = -1;
    } else {
      ungetc(c, infile);
    }
    while(isDigit(c = getc(infile))){
      num = (num * 10) + (c - '0');
    }
    num *= sign;
    if(isDelimiter(cast(char) c)){
      ungetc(c, infile);
      return makeFixnum(num);
    } else {
      throw new StdioException("number not followed by delimiter\n");
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
  } else {
    throw new StdioException("bad input. Unexpected character\n");
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
    string str = obj.stringValue;
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