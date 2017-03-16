{
	const operatorRef = {
    ">=": ">=",
    "<=": "<=",
    "=": "===",
    "eq": "===",
    "not": "!==",
    "neq": "!==",
    ">": ">",
    "<": "<",
    "and" : "&&",
    "or" : "||",
  }
}

program
  = _ r:root+ "\n"*  { return {
      type: 'Rules',
      body: r
    };}

root 
  = _ "(def" _ "const" _ i:ident _ v:sexp _ ")" _ { return {
    type: 'const',
    name: i,
    value: v
  }}
  / _ "(def" _ i:ident _ v:sexp? _ ")" _ { return {
    type: 'var',
    name: i,
    value: v
  }}
  / _ "(defrule" _ r:defrule _ ")" _ { return r; }

sexp
  = _ a:atom _ { return a; }
  / _ l:list _ { return l; }

string = '"' d:(!'"' sourcechar)* '"' _ { return "\"" + d.map(s => s[1]).join("") + "\""}
ident = s:[a-zA-Z0-9_]+ _ { return s.join("")}
float = d:[0-9.]+ { return parseFloat(d.join(""), 10) }
digit = d:[0-9]+ { return parseInt(d.join(""), 10) }
access_attr = l:ident '->' r:atom {return l+'.'+r; }

number
  = d:[+-]? n:(digit / float) { return d === "-" ? -n : n }

atom
  = number
  / access_attr
  / string
  / ident
  

arithmetic_operator = "+" / "-" / "*" / "/"
compare_operator_binary = ">=" / "<=" / "=" / "eq" / "not" / "neq" / ">" / "<"
compare_operator_multiple = "and" / "or"
multiple_operator 
  = arithmetic_operator 
  / o:compare_operator_multiple { return operatorRef[o]; }


comparision
  = _ "in" _ element:sexp _ array:sexp {
    return array + ".indexOf(" + element + ") > -1" ;
  }
  / _ o:compare_operator_binary _ e1:sexp _ e2:sexp {
    return e1 + ' ' + operatorRef[o] + ' ' + e2;
  }

list
  = _ "()" _ { return []; }
  / _ "(list" _ s:sexp+ _ ")" _ { return '[' + s.join(', ') + ']'}
  / _ "(" _ c:closed_list _ ")" _ { return '(' + c + ')'; }
  / _ "(" _ s:sexp+ _ ")" _ {
    const fn = s[0];
    console.log('fn', fn);
    const args = s.slice(1);
    return fn + "(" + args.join(",") + ")"; 
  }

closed_list
  = c:comparision { return c; }
  / operator:multiple_operator _ operands:sexp+ {
    return operands.join(' ' + operator + ' ');
  }

// defrule
defrule = _ name:ident
  _ headers: (_ headers:rule_header+
  _ "--" { return headers})?
  _ conditions:rule_condition+ 
  _ "=>" 
  _ asserts:rule_assertion+ _ {
    const rule = Object.assign({
    	type: "rule",
        name,
        asserts,
    }, 	headers === null ? {} : headers
          .reduce((o, h) => Object.assign(o, h), {}),
    	{condition: conditions.join(" && ")}
    );
    
  	return rule;
  }

rule_header
	= _ "(priority" _ p:number _ ")" { return { priority: p } }
	/ _ "(scope" _ s:ident _ ")" { return { scope: s } }
rule_condition 
	= _ "(" _ name:atom _ value:atom ")" _ {
    return "(" + name + "=="  + value + ")"
  }
  / sexp

rule_assertion
	= _ "(" _ "attr" _ a:rule_assert_attribute _ ")" _ { 
    return { type: "attribute", value: a }
  }
	/ _ "(tag" _ t:rule_assert_tag _ ")" _ { return { type: "tag", value: t } }
  / _ "(assert" _ m:temporary_assert _ ")" { return {type: "assert", value: m} }

rule_assert_attribute
	= _ "(" _ r:rule_assert_attribute_counter _ ")" _ { return r; }

rule_assert_attribute_counter
  = "+" _ name:ident _ value:sexp {
    return {
      operator: "+",
      name,
      value,
    }
  }

rule_assert_tag
	= _ name:atom _ cf:float _ { return { name, cf };}

temporary_assert
  = _ "(" _ name:ident value:sexp _ ")" _ { return {name, value}; }

sourcechar
  = .

comment
  = ";;" s:(!"\n" sourcechar)* "\n"

__
  = [\n, ]

_
  = (__ / comment)*

