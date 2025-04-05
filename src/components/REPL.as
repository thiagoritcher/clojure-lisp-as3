package components
{
	public class REPL 
	{

        private const STATE_WAIT:int = 0;
        private const STATE_EVAL_EXP:int = 100;
		
		private var ex:Exec;

		public function REPL() {
			ex = new Exec(this);
		}
        public function run(str:String):*{
			return eval_cmds(parse(str)[0])
		}

        public function exec(op:String, args:Array, locals:Object = null, globals:Object = null):*{

			switch(op){
				case "+": 
				case "-":
				case "*":
				case "/": return ex.domath(op,args);
				case "<": 
				case ">": 
                case ">=": 
                case "<=": 
                case "==": 
                case "eq":
                case "neq":
                case "!=": return ex.docompare(op, args);
				case "print": return ex.print(args);
				case "list": return ex.str(args);
				case "str": return ex.str(args);
				case "def": return ex.def(args);
				case "fn": return ex.fun(args);
				case "if": return ex.doif(args);
				case "quote": return ex.quote(args);
				case "do": return ex.exdo(args, locals, globals);
				case "defmacro": return ex.defmacro(args);
				default:
					return ex.dofn(op, args);
						
			}
		}

        public function eval_cmds(cmds:Array, locals:Object = null, globals:Object = null):*{
            var res:* = null;
            for(var i:int = 0; i < cmds.length; i++){
                res = eval(cmds[i], locals, globals); 
            }
            return res;
        }

        public function eval(data:*, locals:Object = null, globals:Object = null, ismacro:Boolean = false):*{
            if(!(data is Array)){
                if(data == "nil"){
                    return null;
                }
                else if(data == "true"){
                    return true;
                }
                else if(data == "false"){
                    return false;
                }
                else if(locals != null && locals.hasOwnProperty(data)){
                    return locals[data];
                }
                else if(globals != null && globals.hasOwnProperty(data)){
                    return globals[data];
                }
                else {
                    throw "Unknown variable: " + data;
                }
            }

            var op:String = data[0];
            var args:Array = [];
            var k:int = 0;
                
            if("fn" == op || 'defmacro' == op || 'if' == op){
                args = data.slice(1);
                return exec(op, args);
            }
            
            if(is_wrap(op)){
                args = data.slice(1);
                return exec(op, args);
            }

            for(var i:int = 1; i < data.length; i++){
                if(data[i] is Array){
                    args[k++] = eval(data[i], locals, globals);
                }
                else if(locals != null && locals.hasOwnProperty(data[i])){
                    args[k++] = locals[data[i]];
                }
                else if(globals != null && globals.hasOwnProperty(data[i])){
                    args[k++] = globals[data[i]];
                }
                else if(data[i].length > 1 && data[i].charAt(0) == ":"){
                    args[k++] = data[i].substr(1, data[i].length -2);
                }
                else {
                    args[k++] = Number(data[i])
                }
            }
            if(ismacro){
                return args;
            }
            else {
                return exec(op, args); 

            }
            
		}

        private function dowrap(wrap:String, val:*):Array{
           return [wrap, val]; 
        }
        
        private function is_wrap(op:String):Boolean{
           switch(op){
               case "quote": return true;
               case "sintax_quote": return true;
               case "sintax_unquote_splicing": return true;
               case "sintax_unquote": return true;
           }
           return false;
        }
        
        private function get_wrap(val:String, next:String):String{
           switch(val){
               case "'": return "quote"
               case "`": return "sintax_quote"
               case "~": return next == "@" ? "sintax_unquote_splicing": "sintax_unquote";
               default : return null
           }
        }

        public function parse(value:String, start:int = 0, level:int = 0):Array{
            var str:Boolean = false;
            var state:int = STATE_EVAL_EXP
            var wrap:String = null;

			var current:String = ""
			var start_level:int = level
			
			var parts:Array = [];
            for(var i:int = start; i < value.length; i++){
                var c:String = value.charAt(i)
                var nxt:String = i < value.length - 1 ? value.charAt(i + 1) : null;
                
                var cwrap:String = get_wrap(c, nxt);
                if(cwrap && !str){
                    wrap = cwrap;
                    continue;
                }
				if(c == "(" &&  state == STATE_EVAL_EXP && !str){
					var p:* = parse(value, i + 1, level + 1);
					if(p[0]){
                        if(wrap){
                            parts.push(dowrap(wrap, p[0]));
                            wrap = null;
                        }
                        else {
                            parts.push(p[0]);
                        }
                    }
					i = p[1];
					continue;	
				}
                else if(c == ")" && state == STATE_EVAL_EXP && !str){
					level--
                    if(current){
                        if(wrap){
                            parts.push(dowrap(wrap, current));
                            wrap = null;
                        }
                        else {
                            parts.push(current);
                        }
                    }
                    return [parts, i];
                }
                else if(c == "\"" && state == STATE_EVAL_EXP){
					str = !str;
					current += ":";
                    continue;
                }
				else if( c == " " && level == start_level && !str) {
					if(current == " "){
						continue;
					}

					if(current == ""){
						continue;
					}

                    if(wrap){
                        parts.push(dowrap(wrap, current));
                        wrap = null;
                    }
                    else {
                        parts.push(current)
                    }
					current = "";
				}
				else {
					current += c;
				}
            }
			return [parts, i];
        }

        private function pp(args:*):*{
            trace(JSON.stringify(args, null, 2));
        }
	}
}

class Exec {
	
	private var repl:*;
	
	public function Exec(r:*){
		this.repl = r;
	}

	private var defs:Object = {
		native: {},
		internal: {}
	};

	public function docompare(op:String, args:Array):*{	
		var r:Boolean;
        switch(op){
           case "=": 
           case "eq": r = args[0] == args[1]; break;
           case "!=":
           case "neq": r = args[0] != args[1]; break;
           case ">": r = args[0] > args[1]; break;
           case ">=": r = args[0] >= args[1]; break;
           case "<": r = args[0] < args[1]; break;
           case "<=": r = args[0] <= args[1]; break;
        }
		return r;
	}
	public function domath(op:String, args:Array):*{	
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
            switch(op){
               case "+": s += args[i]; break; 
               case "*": s *= args[i]; break; 
               case "-": s -= args[i]; break; 
               case "/": s /= args[i]; break; 
            }
		}
		return s;
	}

	public function add(args:Array):*{	
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
			s += args[i];	
		}
		return s;
	}
	
    public function divide(args:Array):*{	
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
			s /= args[i];	
		}
		return s;
	}
    
    public function mult(args:Array):*{	
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
			s *= args[i];	
		}
		return s;
	}
    
    public function str(args:Array):*{	
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
			s += args[i];	
		}
		return s;
	}
    
    public function list(args:Array):*{	
        return args;
	}

    public function print(args:*):void{
        trace(args);
    }

	public function doif(args:Array):Object {
        if(repl.eval(args[0], null, defs.internal)){
            return repl.eval(args[1], null, defs.internal);
        }
        else {
            if(args.length < 3) return null;
            return repl.eval(args[2], null, defs.internal);  
        }
	}

	public function fun(args:Array):Object {
		return {
			type: '#function',
			param: args[0], 
			body: args[1]
		}
	}
	
    public function quote(args:Array):* {
		return args[0];
	}

	public function def(args:Array):* {
		defs.internal[args[0]] = args[1];
		return args;
	}
	
    public function exdo(args:Array, locals:Object, globals:Object):* {
        var res:* = null; 
		for(var i:int = 1; i < args.length; i++){
            res = repl.eval(args[i], locals, globals);
		}
        return res;
	}
	
    public function defmacro(args:Array):* {
        var macro:Object = {
			type: '#macro',
			param: args[1], 
			body: args[2]
		};
        pp(macro);

		defs.internal[args[0]] = macro;
		return args;
	}
	
	public function dofn(fn:String, args:Array):*{	
		if(fn.charAt(0) == '.'){
			var obj:* = defs.native[args[0]]
			var fnd:Function = obj[fn.substring(1)];
			return fnd.apply(obj, args.slice(1))
		}
		else {
			var def:Object = defs.internal[fn];
            var locals:Object = {};
            var l:int;
            if(def.type == '#function'){
                for(l = 0; l < def.param.length; l++){
                    locals[def.param[l]] = args[l];
                }

                return repl.eval(def.body, locals, defs.internal);
            }
            else if(def.type == '#macro'){
                if(!def.evalres){
                    for(l = 0; l < def.param.length; l++){
                        locals[def.param[l]] = def.param[l];
                    }
                    def.evalres = repl.eval(def.body, locals, defs.internal, true);
                }

                for(l = 0; l < def.param.length; l++){
                    locals[def.param[l]] = args[l];
                }
                return repl.eval(def.evalres, locals, defs.internal);
            }
            else {
                throw "funcao nao definida: " + args.type;
            }
		}
		var s:* = args[0];
		for(var i:int = 1; i < args.length; i++){
			s += args[i];	
		}
		return s;
	}

    private function pp(args:*):*{
        trace(JSON.stringify(args, null, 2));
    }
}
