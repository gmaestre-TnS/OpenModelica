/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package BackendVariable
" file:        mo
  package:     BackendVariable
  description: BackendVariables contains the function that deals with the datytypes
               BackendDAE.VAR BackendDAE.Variables and BackendVariablesArray.

  RCS: $Id$
"

public import BackendDAE;
public import DAE;
public import FCore;
public import SCode;
public import Values;

protected import Absyn;
protected import Array;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BaseHashSet;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import List;
protected import System;
protected import Util;
protected import Types;

/* =======================================================
 *
 *  Section for type definitions
 *
 * =======================================================
 */

protected constant Real HASHVECFACTOR = 1.4;

/* =======================================================
 *
 *  Section for functions that deals with Var
 *
 * =======================================================
 */

public function varEqual "author: PA
  Returns true if two vars are equal."
  input BackendDAE.Var inVar1;
  input BackendDAE.Var inVar2;
  output Boolean outBoolean;
protected
  DAE.ComponentRef cr1, cr2;
algorithm
  BackendDAE.VAR(varName=cr1) := inVar1;
  BackendDAE.VAR(varName=cr2) := inVar2;
  outBoolean := ComponentReference.crefEqualNoStringCompare(cr1, cr2) "a BackendDAE.Var is identified by its component reference";
end varEqual;

public function setVarFixed "author: PA
  Sets the fixed attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean inBoolean;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setFixedAttr(oattr, SOME(DAE.BCONST(inBoolean)));
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarFixed;

public function varFixed "author: PA
  Extracts the fixed attribute of a variable.
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inVar)
    local
      Boolean fixed;

    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_BOOL(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(fixed=SOME(DAE.BCONST(fixed)))))) then fixed;

    // params and consts are by default fixed
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM())) then true;
    case (BackendDAE.VAR(varKind = BackendDAE.CONST(),bindExp=SOME(_))) then true;

    // rest defaults to false
    else false;
  end matchcontinue;
end varFixed;

public function setVarStartValue "author: Frenkel TUD
  Sets the start value attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct,io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setStartAttr(oattr, inExp);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct,io, unreplaceable);
end setVarStartValue;

public function setVarStartValueOption "author: Frenkel TUD
  Sets the start value attribute of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> inExp;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setStartAttrOption(oattr, inExp);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarStartValueOption;

public function setVarStartOrigin "author: Frenkel TUD
  Sets the startOrigin attribute of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> startOrigin;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setStartOrigin(oattr, startOrigin);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarStartOrigin;

public function setVarAttributes "sets the variable attributes of a variable.
  author: Peter Aronsson (paronsson@wolfram.com)"
  input BackendDAE.Var v;
  input Option<DAE.VariableAttributes> attr;
  output BackendDAE.Var outV;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  Option<SCode.Comment> s;
  Option<BackendDAE.TearingSelect> ts;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, _, ts, s, ct, io, unreplaceable) := v;
  outV := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, attr, ts, s, ct, io, unreplaceable);
end setVarAttributes;

public function varStartValue "author: PA
  Returns the DAE.StartValue of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values=attr) := v;
  sv := DAEUtil.getStartAttr(attr);
end varStartValue;

public function varUnreplaceable "author: lochel
  Returns the unreplaceable attribute of a variable."
  input BackendDAE.Var inVar;
  output Boolean outUnreplaceable;
algorithm
  BackendDAE.VAR(unreplaceable=outUnreplaceable) := inVar;
end varUnreplaceable;

public function varStartValueFail "author: Frenkel TUD
  Returns the DAE.StartValue of a variable if there is one.
  Otherwise fail"
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getStartAttrFail(attr);
end varStartValueFail;

public function varNominalValueFail "author: lochel
  Returns the DAE.NominalValue of a variable if there is one.
  Otherwise fails."
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getNominalAttrFail(attr);
end varNominalValueFail;

public function varMinValueFail "author: lochel
  Returns the DAE.MinValue of a variable if there is one.
  Otherwise fails."
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getMinAttrFail(attr);
end varMinValueFail;

public function varMaxValueFail "author: lochel
  Returns the DAE.MaxValue of a variable if there is one.
  Otherwise fails."
  input BackendDAE.Var v;
  output DAE.Exp sv;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  sv := DAEUtil.getMaxAttrFail(attr);
end varMaxValueFail;

public function varStartValueType "author: Frenkel TUD 2012-11
  Returns the DAE.StartValue of a variable. If nothing is set the type specific one is used"
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
      DAE.Type ty;

    case (BackendDAE.VAR(values=attr)) equation
      sv = DAEUtil.getStartAttrFail(attr);
    then sv;

    case BackendDAE.VAR(varType=ty) equation
      true = Types.isIntegerOrSubTypeInteger(ty);
    then DAE.ICONST(0);

    case BackendDAE.VAR(varType=ty) equation
      true = Types.isBooleanOrSubTypeBoolean(ty);
    then DAE.BCONST(false);

    case BackendDAE.VAR(varType=ty) equation
      true = Types.isStringOrSubTypeString(ty);
    then DAE.SCONST("");

    else DAE.RCONST(0.0);
  end matchcontinue;
end varStartValueType;

public function varStartValueOption "author: Frenkel TUD
  Returns the DAE.StartValue of a variable if there is one.
  Otherwise fail"
  input BackendDAE.Var v;
  output Option<DAE.Exp> sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
      DAE.Exp exp;

    case (BackendDAE.VAR(values=attr)) equation
      exp = DAEUtil.getStartAttrFail(attr);
    then SOME(exp);

    else NONE();
   end matchcontinue;
end varStartValueOption;

public function varHasStartValue
  input BackendDAE.Var inVar;
  output Boolean outHasStartValue;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values=attr) := inVar;
  outHasStartValue := DAEUtil.hasStartAttr(attr);
end varHasStartValue;

public function varHasNoStartValue
  input BackendDAE.Var inVar;
  output Boolean outHasNoStartValue;
algorithm
  outHasNoStartValue := not varHasStartValue(inVar);
end varHasNoStartValue;

public function varStartOrigin "author: Frenkel TUD
  Returns the StartOrigin of a variable."
  input BackendDAE.Var v;
  output Option<DAE.Exp> so;
protected
   Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  so := DAEUtil.getStartOrigin(attr);
end varStartOrigin;

public function varBindExp "author: Frenkel TUD 2010-12
  Returns the bindExp of a variable if available otherwise fails."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  BackendDAE.VAR(bindExp=SOME(sv)) := v;
end varBindExp;

public function varHasConstantBindExp
"Returns the true if the bindExp is constant otherwise false."
  input BackendDAE.Var v;
  output Boolean  out;
algorithm
  out := match(v)
    local
      DAE.Exp e;

    case (BackendDAE.VAR(bindExp=SOME(e)))
    then Expression.isConst(e);

    else false;
  end match;
end varHasConstantBindExp;

public function varHasBindExp
"Returns the true if a bindExp exists otherwise false."
  input BackendDAE.Var v;
  output Boolean  out;
algorithm
  out := match(v)
    local
      DAE.Exp e;

    case (BackendDAE.VAR(bindExp = SOME(_)))
    then true;

    else false;
  end match;
end varHasBindExp;

public function varBindExpStartValue "author: Frenkel TUD 2010-12
  Returns the bindExp or the start value if no bind is there of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := match(v)
    local
      DAE.Exp e;

    case (BackendDAE.VAR(bindExp=SOME(e)))
    then e;

    else varStartValueFail(v);
  end match;
end varBindExpStartValue;

public function varStateSelect "author: PA
  Extracts the state select attribute of a variable. If no stateselect explicilty set, return
  StateSelect.default"
  input BackendDAE.Var inVar;
  output DAE.StateSelect outStateSelect;
algorithm
  outStateSelect := matchcontinue (inVar)
    local
      DAE.StateSelect stateselect;

    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(stateSelectOption=SOME(stateselect)))))
    then stateselect;

    else DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function setVarStateSelect "author: Frenkel TUD
  sets the state select attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.StateSelect stateSelect;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setStateSelect(oattr, stateSelect);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarStateSelect;

public function varStateDerivative "author: Frenkel TUD 2013-01
  Returns the name of the Derivative. Is no Derivative known the function will fail."
  input BackendDAE.Var inVar;
  output DAE.ComponentRef dcr;
algorithm
  BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))) := inVar;
end varStateDerivative;

public function varHasStateDerivative "author: Frenkel TUD 2013-01
  Returns the name of the Derivative. Is no Derivative known the function will fail."
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := match(inVar)
    case BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(_))) then true;
    else false;
  end match;
end varHasStateDerivative;

public function setStateDerivative "author: Frenkel TUD
  sets the state derivative."
  input BackendDAE.Var inVar;
  input Option<DAE.ComponentRef> dcr;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  Integer indx;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=a,
                 varKind=BackendDAE.STATE(index=indx),
                 varDirection=c,
                 varParallelism=prl,
                 varType=d,
                 bindExp=e,
                 bindValue=f,
                 arryDim=g,
                 source=source,
                 values=oattr,
                 tearingSelectOption = ts,
                 comment=s,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(a, BackendDAE.STATE(indx, dcr), c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setStateDerivative;

public function getVariableAttributefromType
  input DAE.Type inType;
  output DAE.VariableAttributes attr;
algorithm
  attr := match(inType)
    case DAE.T_REAL() then DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER() then DAE.VAR_ATTR_INT(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_INTEGER() then DAE.VAR_ATTR_INT(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_BOOL() then DAE.VAR_ATTR_BOOL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_STRING() then DAE.VAR_ATTR_STRING(NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    case DAE.T_ENUMERATION() then DAE.VAR_ATTR_ENUMERATION(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
    else equation
      // repord a warning on failtrace
      if Flags.isSet(Flags.FAILTRACE) then
        Debug.trace("getVariableAttributefromType called with unsopported Type!\n");
      end if;
    then DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());
  end match;
end getVariableAttributefromType;

public function setVarFinal "author: Frenkel TUD
  Sets the final attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean finalPrefix;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setFinalAttr(oattr, finalPrefix);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarFinal;

public function setVarMinMax "author: Frenkel TUD
  Sets the minmax attribute of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> inMin;
  input Option<DAE.Exp> inMax;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  if isSome(inMin) or isSome(inMax) then
    BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
    oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
    oattr := DAEUtil.setMinMax(oattr, inMin, inMax);
    outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
  else
    outVar := inVar;
  end if;
end setVarMinMax;

public function setUnit "author: jhagemann
  Sets the unit attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.Exp inUnit;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setUnitAttr(oattr, inUnit);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setUnit;

public function varNominalValue "author: Frenkel TUD"
  input BackendDAE.Var inVar;
  output DAE.Exp outExp;
algorithm
  BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(nominal=SOME(outExp)))) := inVar;
end varNominalValue;

public function setVarNominalValue "author: Frenkel TUD
  Sets the nominal value attribute of a variable."
  input BackendDAE.Var inVar;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism prl;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  DAE.VariableAttributes attr;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable) := inVar;
  oattr := if isSome(oattr) then oattr else SOME(getVariableAttributefromType(d));
  oattr := DAEUtil.setNominalAttr(oattr, inExp);
  outVar := BackendDAE.VAR(a, b, c, prl, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end setVarNominalValue;

public function varType "author: PA
  extracts the type of a variable"
  input BackendDAE.Var inVar;
  output BackendDAE.Type outType;
algorithm
  BackendDAE.VAR(varType=outType) := inVar;
end varType;

public function varKind "author: PA
  extracts the kind of a variable"
  input BackendDAE.Var inVar;
  output BackendDAE.VarKind outVarKind;
algorithm
  BackendDAE.VAR(varKind=outVarKind) := inVar;
end varKind;

public function varBindValue "author: PA
  extracts the bindValue of a variable"
  input BackendDAE.Var inVar;
  output Values.Value outBindValue;
algorithm
  BackendDAE.VAR(bindValue=SOME(outBindValue)) := inVar;
end varBindValue;

public function varNominal "author: PA
  Extacts the nominal attribute of a variable. If the variable has no
  nominal value, the function fails."
  input BackendDAE.Var inVar;
  output Real outReal;
algorithm
  BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(nominal=SOME(DAE.RCONST(outReal))))) := inVar;
end varNominal;

public function varHasNominalValue "author: BB"
  input BackendDAE.Var inVar;
  output Boolean outBool;
algorithm
  try
    BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(nominal=SOME(DAE.RCONST())))) := inVar;
    outBool := true;
  else
    outBool :=false;
  end try;
end varHasNominalValue;

public function varCref "author: PA
  extracts the ComponentRef of a variable"
  input BackendDAE.Var inVar;
  output DAE.ComponentRef outComponentRef;
algorithm
  BackendDAE.VAR(varName=outComponentRef) := inVar;
end varCref;

public function isStateVar
"Returns true for state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then true;
    else false;
  end match;
end isStateVar;

public function isState
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  output Boolean outBool;
algorithm
  outBool:=
  matchcontinue(inCref, inVars)
    case(_, _) equation
      ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = getVar(inCref, inVars);
    then true;

    else false;
  end matchcontinue;
end isState;

public function isNonStateVar
"this equation checks if the the varkind is state of variable
  used both in build_equation and generate_compute_state"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case _ equation
      failIfNonState(inVar);
    then true;

    else false;
  end matchcontinue;
end isNonStateVar;

public function varHasUncertainValueRefine "author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns true if the specified variable has the attribute uncertain and the
  value of it is Uncertainty.refine, false otherwise."
  input BackendDAE.Var var;
  output Boolean b;
algorithm
  b := matchcontinue (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(uncertainOption=SOME(DAE.REFINE()))))) then true;
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(uncertainOption=SOME(DAE.REFINE()))))) then true;
    else false;
  end matchcontinue;
end varHasUncertainValueRefine;

public function varDistribution "author: Peter Aronsson, 2012-05
  Returns Distribution record of a variable."
  input BackendDAE.Var var;
  output DAE.Distribution d;
algorithm
  d := match (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(distributionOption=SOME(d))))) then d;
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(distributionOption=SOME(d))))) then d;
  end match;
end varDistribution;

public function varTryGetDistribution "author: Peter Aronsson, 2012-05
  Returns Distribution record of a variable."
  input BackendDAE.Var var;
  output Option<DAE.Distribution> dout;
  protected DAE.Distribution d;
algorithm
  dout := match (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(distributionOption=SOME(d))))) then SOME(d);
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(distributionOption=SOME(d))))) then SOME(d);
    else NONE();
  end match;
end varTryGetDistribution;

public function varUncertainty "author: Peter Aronsson, 2012-05
  Returns Uncertainty of a variable."
  input BackendDAE.Var var;
  output DAE.Uncertainty u;
algorithm
  u := match (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(uncertainOption=SOME(u))))) then u;
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(uncertainOption=SOME(u))))) then u;
  end match;
end varUncertainty;

public function varHasDistributionAttribute "author: Peter Aronsson, 2012-05
  Returns true if the specified variable has the attribute distribution set."
  input BackendDAE.Var var;
  output Boolean b;
algorithm
  b := match (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(distributionOption=SOME(_))))) then true;
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(distributionOption=SOME(_))))) then true;
    else false;
  end match;
end varHasDistributionAttribute;

public function varHasUncertaintyAttribute "author: Peter Aronsson, 2012-05
  Returns true if the specified variable has the attribute uncertain set."
  input BackendDAE.Var var;
  output Boolean b;
algorithm
  b := match (var)
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_REAL(uncertainOption=SOME(_))))) then true;
    case (BackendDAE.VAR(values=SOME(DAE.VAR_ATTR_INT(uncertainOption=SOME(_))))) then true;
    else false;
  end match;
end varHasUncertaintyAttribute;

protected function failIfNonState "Fails if the given variable kind is state."
  input BackendDAE.Var inVar;
algorithm
  _ := match (inVar)
    case (BackendDAE.VAR(varKind=BackendDAE.VARIABLE())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.DISCRETE())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.STATE_DER())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_CONSTR())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_FCONSTR())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_INPUT_WITH_DER())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_INPUT_DER())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_TGRID())) then ();
    case (BackendDAE.VAR(varKind=BackendDAE.OPT_LOOP_INPUT())) then ();
    case BackendDAE.VAR(varKind=BackendDAE.ALG_STATE()) then ();
  end match;
end failIfNonState;

public function isDummyStateVar "Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then true;
    else false;
  end match;
end isDummyStateVar;

public function isDummyDerVar
"Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())) then true;
    else false;
  end match;
end isDummyDerVar;

public function isStateDerVar "
  Returns true for der(state) variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())) then true;
    else false;
  end match;
end isStateDerVar;

public function isStateorStateDerVar
"Returns true for state and der(state) variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then true;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())) then true;
    else false;
  end match;
end isStateorStateDerVar;

public function isVarDiscrete
"This functions checks if BackendDAE.Var is discrete"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())) then true;
    case (BackendDAE.VAR(varType = DAE.T_INTEGER())) then true;
    case (BackendDAE.VAR(varType = DAE.T_BOOL())) then true;
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION())) then true;
    else false;
  end match;
end isVarDiscrete;

public function isDiscrete
"This functions checks if BackendDAE.Var is discrete"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Boolean outBoolean;
protected
  BackendDAE.Var v;
algorithm
  ({v},_) := getVar(cr,vars);
  outBoolean := isVarDiscrete(v);
end isDiscrete;

public function isVarNonDiscrete
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := not isVarDiscrete(inVar);
end isVarNonDiscrete;

public function hasDiscreteVar
"Returns true if var list contains a discrete time variable."
  input list<BackendDAE.Var> inBackendDAEVarLst;
  output Boolean outBoolean = false;
algorithm

  for v in inBackendDAEVarLst loop
    outBoolean := isVarDiscrete(v);
    if outBoolean then
      break;
    end if;
  end for;

end hasDiscreteVar;

public function hasContinousVar
"Returns true if var list contains a continous time variable."
  input list<BackendDAE.Var> inBackendDAEVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inBackendDAEVarLst)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;

    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_REAL()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.VARIABLE(),varType = DAE.T_ARRAY(ty=DAE.T_REAL())) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.STATE_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_CONSTR()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_FCONSTR()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_INPUT_WITH_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_INPUT_DER()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_TGRID()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.OPT_LOOP_INPUT()) :: _)) then true;
    case ((BackendDAE.VAR(varKind=BackendDAE.ALG_STATE()) :: _)) then true;
    case ((_ :: vs)) then hasContinousVar(vs);
    case ({}) then false;
  end match;
end hasContinousVar;

public function isVarNonDiscreteAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;

    /* Real non discrete variable */
    case (BackendDAE.VAR(varKind = kind, varType = DAE.T_REAL(_,_))) equation
      kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DUMMY_DER(), BackendDAE.DUMMY_STATE(), BackendDAE.OPT_INPUT_WITH_DER(), BackendDAE.OPT_INPUT_DER()};
    then listMember(kind, kind_lst) or isOptLoopInput(kind);

    else false;
  end match;
end isVarNonDiscreteAlg;

protected function isOptLoopInput
  input BackendDAE.VarKind kind;
  output Boolean b;
algorithm
  b := match(kind) case(BackendDAE.OPT_LOOP_INPUT()) then true;
                   else false;
       end match;
end isOptLoopInput;

public function isVarDiscreteAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;

    /* Real discrete variable */
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), varType = DAE.T_REAL(_,_)))
    then true;

    else false;
  end match;
end isVarDiscreteAlg;

/* TODO: Is this correct? */
public function isVarStringAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;

    /* string variable */
    case (BackendDAE.VAR(varKind = kind, varType = DAE.T_STRING())) equation
      kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(), BackendDAE.DUMMY_STATE()};
    then listMember(kind, kind_lst);

    else false;
  end match;
end isVarStringAlg;

public function isVarIntAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result := match (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = DAE.T_INTEGER()))
      equation

        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
    case (BackendDAE.VAR(varKind = kind,
                     varType = DAE.T_ENUMERATION()))
      equation

        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);

    else false;
  end match;
end isVarIntAlg;

public function isVarBoolAlg
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.VarKind kind;
      BackendDAE.Type typeVar;
      list<BackendDAE.VarKind> kind_lst;
    /* int variable */
    case (BackendDAE.VAR(varKind = kind,
                     varType = DAE.T_BOOL()))
      equation
        kind_lst = {BackendDAE.VARIABLE(), BackendDAE.DISCRETE(), BackendDAE.DUMMY_DER(),
                    BackendDAE.DUMMY_STATE()};
      then listMember(kind, kind_lst);
    else false;
  end matchcontinue;
end isVarBoolAlg;

public function isVarConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* bool variable */
    case (BackendDAE.VAR(varType = DAE.T_BOOL()))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varType = DAE.T_INTEGER()))
      then false;
    /* enum variable */
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION()))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_STRING()))
      then false;
    /* non-string variable */
    case _
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarConst;

public function isVarStringConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_STRING()))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringConst;

public function isVarIntConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* int variable */
    case (BackendDAE.VAR(varType = DAE.T_INTEGER()))
      equation
        true = isConst(var);
      then true;
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION()))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntConst;

public function isVarBoolConst
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_BOOL()))
      equation
        true = isConst(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolConst;

/* TODO: Is this correct? */
public function isVarParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* bool variable */
    case (BackendDAE.VAR(varType = DAE.T_BOOL()))
      then false;
    /* int variable */
    case (BackendDAE.VAR(varType = DAE.T_INTEGER()))
      then false;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_STRING()))
      then false;
    /* enum variable */
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION()))
      then false;
    /* non-string variable */
    case _
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarParam;


public function isVarStringParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_STRING()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringParam;


public function isVarIntParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    // int variable
    case (BackendDAE.VAR(varType = DAE.T_INTEGER()))
      equation
        true = isParam(var);
      then true;
    // enum is also mapped to long
    case (BackendDAE.VAR(varType = DAE.T_ENUMERATION()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntParam;

public function isVarBoolParam
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      BackendDAE.Type typeVar;
    /* string variable */
    case (BackendDAE.VAR(varType = DAE.T_BOOL()))
      equation
        true = isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolParam;

public function isVarConnector
  input BackendDAE.Var var;
  output Boolean result;
algorithm
  result :=
  match (var)
    case BackendDAE.VAR(connectorType = DAE.NON_CONNECTOR()) then false;
    else true;
  end match;
end isVarConnector;

public function isFlowVar
"Returns true for flow variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(connectorType = DAE.FLOW()) then true;
    else false;
  end matchcontinue;
end isFlowVar;

public function isConst
"Return true if variable is a constant."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(varKind = BackendDAE.CONST()) then true;
    case (_) then false;
  end matchcontinue;
end isConst;

public function isParam
"Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(varKind = BackendDAE.PARAM()) then true;
    case BackendDAE.VAR(varKind = BackendDAE.OPT_TGRID()) then true;
    case (_) then false;
  end matchcontinue;
end isParam;

public function isIntParam
"Return true if variable is a parameter and integer."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_INTEGER())) then true;
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_ENUMERATION())) then true;
    case (_) then false;
  end matchcontinue;
end isIntParam;

public function isBoolParam
"Return true if variable is a parameter and boolean."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_BOOL())) then true;
    case (_) then false;
  end matchcontinue;
end isBoolParam;

public function isStringParam
"Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_STRING())) then true;
    case (_) then false;
  end matchcontinue;
end isStringParam;

public function isExtObj
"Return true if variable is an external object."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.EXTOBJ(_))) then true;
    case (_) then false;
  end matchcontinue;
end isExtObj;

public function isAlgState
"Return true if variable is alg state"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case BackendDAE.VAR(varKind=BackendDAE.ALG_STATE()) then true;
    else false;
  end match;
end isAlgState;

public function isRealParam
"Return true if variable is a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = DAE.T_REAL())) then true;
    case (_) then false;
  end matchcontinue;
end isRealParam;

public function isRealOptimizeConstraintsVars
"Return true if variable is a constraint(slack variable)"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.OPT_CONSTR())) then true;
    else false;
  end match;
end isRealOptimizeConstraintsVars;

public function isRealOptimizeFinalConstraintsVars
"Return true if variable is a final constraint(slack variable)"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.OPT_FCONSTR())) then true;
    else false;
  end match;
end isRealOptimizeFinalConstraintsVars;

public function isRealOptimizeDerInput
"Return true if variable replaced der(Input)"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (BackendDAE.VAR(varKind =  BackendDAE.OPT_INPUT_DER())) then true;
    else false;
  end match;
end isRealOptimizeDerInput;

public function hasMayerTermAnno
"author: Vitalij Ruge
 Return true if variable has isMayer=true annotation"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    local SCode.Comment comm;

    case (BackendDAE.VAR(comment= SOME(comm) ))
       then SCode.commentHasBooleanNamedAnnotation(comm, "isMayer");
    else false;
  end match;
end hasMayerTermAnno;

public function hasLagrangeTermAnno
"author: Vitalij Ruge
 Return true if variable has isLagrange=true annotation"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    local SCode.Comment comm;

    case (BackendDAE.VAR(comment=  SOME(comm) ))
       then SCode.commentHasBooleanNamedAnnotation(comm, "isLagrange");
    else false;
  end match;
end hasLagrangeTermAnno;

public function hasConTermAnno
"author: Vitalij Ruge
 Return true if variable has isConstraint=true annotation"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    local SCode.Comment comm;

    case (BackendDAE.VAR(comment=  SOME(comm) ))
       then SCode.commentHasBooleanNamedAnnotation(comm, "isConstraint");
    else false;
  end match;
end hasConTermAnno;

public function hasFinalConTermAnno
"author: Vitalij Ruge
 Return true if variable has isFinalConstraint=true annotation"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    local SCode.Comment comm;

    case (BackendDAE.VAR(comment=  SOME(comm) ))
       then SCode.commentHasBooleanNamedAnnotation(comm, "isFinalConstraint");
    else false;
  end match;
end hasFinalConTermAnno;

public function hasTimeGridAnno
"author: Vitalij Ruge
 Return true if variable has isTimeGrid=true annotation"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    local SCode.Comment comm;

    case (BackendDAE.VAR(comment=  SOME(comm) ))
       then SCode.commentHasBooleanNamedAnnotation(comm, "isTimeGrid");
    else false;
  end match;
end hasTimeGridAnno;


public function isNonRealParam
"Return true if variable is NOT a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := not isRealParam(inVar);
end isNonRealParam;

public function isInput
"Returns true if variable is declared as input.
  See also is_ouput above"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.INPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isInput;

public function isOutputVar "Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.OUTPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isOutputVar;

public function isOutput
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  output Boolean outBool;
algorithm
  outBool:=
  matchcontinue(inCref, inVars)
    case(_, _) equation
      ((BackendDAE.VAR(varDirection = DAE.OUTPUT()) :: _),_) = getVar(inCref, inVars);
    then true;

    else false;
  end matchcontinue;
end isOutput;

public function isProtectedVar
"author: Frenkel TUD 2013-01
  Returns the DAE.Protected attribute."
  input BackendDAE.Var v;
  output Boolean prot;
protected
  Option<DAE.VariableAttributes> attr;
algorithm
  BackendDAE.VAR(values = attr) := v;
  prot := DAEUtil.getProtectedAttr(attr);
end isProtectedVar;

public function hasVarEvaluateAnnotationOrFinal
  input BackendDAE.Var inVar;
  output Boolean select;
algorithm
  select := isFinalVar(inVar) or hasVarEvaluateAnnotation(inVar);
end hasVarEvaluateAnnotationOrFinal;

public function hasVarEvaluateAnnotationOrFinalOrProtected
  input BackendDAE.Var inVar;
  output Boolean select;
protected
  DAE.ComponentRef cref;
algorithm
  select := isFinalOrProtectedVar(inVar) or hasVarEvaluateAnnotation(inVar);
end hasVarEvaluateAnnotationOrFinalOrProtected;

public function hasVarEvaluateAnnotation
  input BackendDAE.Var inVar;
  output Boolean select;
algorithm
  select := match(inVar)
    local
      SCode.Annotation anno;
    // Parameter with evaluate=true
    case BackendDAE.VAR(comment=SOME(SCode.COMMENT(annotation_=SOME(anno))))
      then SCode.hasBooleanNamedAnnotation(anno,"Evaluate");
    else false;
  end match;
end hasVarEvaluateAnnotation;

public function hasAnnotation"checks if the variable has an annotation"
  input BackendDAE.Var inVar;
  output Boolean hasAnnot;
algorithm
  hasAnnot := match(inVar)
    local
    case BackendDAE.VAR(comment=SOME(SCode.COMMENT(annotation_=SOME(_))))
      then true;
    else false;
  end match;
end hasAnnotation;

public function getNamedAnnotation
  "Returns the value of the given annotation, or fails if the variable doesn't
   have the annotation."
  input BackendDAE.Var inVar;
  input String inName;
  output Absyn.Exp outValue;
protected
  SCode.Annotation ann;
algorithm
  BackendDAE.VAR(comment = SOME(SCode.COMMENT(annotation_ = SOME(ann)))) := inVar;
  outValue := SCode.getNamedAnnotation(ann, inName);
end getNamedAnnotation;

public function getAnnotationComment"gets the annotation comment, if there is one"
  input BackendDAE.Var inVar;
  output Option<SCode.Comment> comment;
algorithm
  comment := match(inVar)
    local
      Option<SCode.Comment> com;
    case BackendDAE.VAR(comment=com)
      then com;
    else fail();
  end match;
end getAnnotationComment;

public function createpDerVar
"Creates a variable with $pDER.v as cref for jacobian variables."
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
algorithm
  cr := varCref(inVar);
  cr := ComponentReference.makeCrefQual(BackendDAE.partialDerivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, cr);
  outVar := copyVarNewName(cr,inVar);
  outVar := setVarKind(outVar,BackendDAE.JAC_DIFF_VAR());
end createpDerVar;

public function createAliasDerVar
"Creates an alias variable with the name $DER_inCref for a der-call."
  input DAE.ComponentRef inCref;
  output BackendDAE.Var outVar;
protected
  BackendDAE.Var var;
  DAE.ComponentRef cr;
algorithm
  cr := ComponentReference.prependStringCref(BackendDAE.derivativeNamePrefix, inCref);
  outVar := BackendDAE.VAR(cr, BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},
                          DAE.emptyElementSource,
                          NONE(),
                          NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
end createAliasDerVar;

public function createVar
"Creates a  variable with <input> as cref"
  input DAE.ComponentRef inCref;
  input String prependStringCref;
  output BackendDAE.Var outVar;
protected
  BackendDAE.Var var;
  DAE.ComponentRef cr;
algorithm
  cr := ComponentReference.appendStringLastIdent(prependStringCref, inCref);
  outVar := makeVar(cr);
end createVar;

public function createCSEVar "Creates a cse variable with the name of inCref.
  TODO: discrete real varaibales are not treated correctly"
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  output BackendDAE.Var outVar;
algorithm
  outVar := match (inCref)
    local
      DAE.ElementSource source;
      list<Absyn.Path> typeLst;
      Absyn.Path path;
      BackendDAE.VarKind varKind;

    case (_) guard(ComponentReference.traverseCref(inCref, ComponentReference.crefIsRec, false)) equation
      DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path), source=typeLst) = inType;
      source = DAE.SOURCE(Absyn.dummyInfo, {}, NONE(), {}, path::typeLst, {}, {});
      varKind = if Types.isDiscreteType(inType) then BackendDAE.DISCRETE() else BackendDAE.VARIABLE();
      outVar = BackendDAE.VAR(inCref, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), inType, NONE(), NONE(), {}, source, NONE(), SOME(BackendDAE.AVOID()), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
    then outVar;

    case (_) equation
      varKind = if Types.isDiscreteType(inType) then BackendDAE.DISCRETE() else BackendDAE.VARIABLE();
      outVar = BackendDAE.VAR(inCref, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), inType, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), SOME(BackendDAE.AVOID()), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
    then outVar;
  end match;
end createCSEVar;

public function copyVarNewName "author: Frenkel TUD 2012-5
  Create variable with new name as cref from other var."
  input DAE.ComponentRef cr;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
protected
  BackendDAE.VarKind kind;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<DAE.Exp> bind;
  Option<Values.Value> v;
  list<DAE.Dimension> dim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varKind=kind,
                 varDirection=dir,
                 varParallelism=prl,
                 varType=tp,
                 bindExp=bind,
                 bindValue=v,
                 arryDim=dim,
                 source=source,
                 values=attr,
                 tearingSelectOption=ts,
                 comment=comment,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(cr, kind, dir, prl, tp, bind, v, dim, source, attr, ts, comment, ct, io, unreplaceable);
end copyVarNewName;

public function setVarKindForVar"updates the varkind for an indexed var inside the variable-array.
author:Waurich TUD 2015-02"
  input Integer idx;
  input BackendDAE.VarKind kind;
  input BackendDAE.Variables varsIn;
  output BackendDAE.Variables varsOut;
protected
  BackendDAE.Var var;
algorithm
  var := getVarAt(varsIn,idx);
  var := setVarKind(var,kind);
  varsOut := setVarAt(varsIn,idx,var);
end setVarKindForVar;

public function setVarsKind "author: lochel
  This function sets the BackendDAE.VarKind of a variable-list."
  input list<BackendDAE.Var> inVars;
  input BackendDAE.VarKind inVarKind;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := List.map1(inVars,setVarKind,inVarKind);
end setVarsKind;

public function setVarKind "author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.VarKind inVarKind;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<DAE.Exp> bind;
  Option<Values.Value> v;
  list<DAE.Dimension> dim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  BackendDAE.Var oVar;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=cr,
                 varDirection=dir,
                 varParallelism=prl,
                 varType=tp,
                 bindExp=bind,
                 bindValue=v,
                 arryDim=dim,
                 source=source,
                 values=attr,
                 tearingSelectOption=ts,
                 comment=comment,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(cr, inVarKind, dir, prl, tp, bind, v, dim, source, attr, ts, comment, ct, io, unreplaceable);
  // referenceUpdate(inVar, 2, new_kind);
end setVarKind;

public function setBindExp "author: lochel"
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> inBindExp;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
  BackendDAE.VarKind varKind;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<Values.Value> v;
  list<DAE.Dimension> dim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  BackendDAE.Var oVar;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=cr,
                 varKind=varKind,
                 varDirection=dir,
                 varParallelism=prl,
                 varType=tp,
                 bindValue=v,
                 arryDim=dim,
                 source=source,
                 values=attr,
                 tearingSelectOption=ts,
                 comment=comment,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(cr, varKind, dir, prl, tp, inBindExp, v, dim, source, attr, ts, comment, ct, io, unreplaceable);
end setBindExp;

public function setBindValue "author: lochel"
  input BackendDAE.Var inVar;
  input Option<Values.Value> inBindValue;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
  BackendDAE.VarKind varKind;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<DAE.Exp> bindExp;
  list<DAE.Dimension> dim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=cr,
                 varKind=varKind,
                 varDirection=dir,
                 varParallelism=prl,
                 varType=tp,
                 bindExp=bindExp,
                 arryDim=dim,
                 source=source,
                 values=attr,
                 tearingSelectOption=ts,
                 comment=comment,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(cr, varKind, dir, prl, tp, bindExp, inBindValue, dim, source, attr, ts, comment, ct, io, unreplaceable);
end setBindValue;

public function setVarDirectionTpl
  input BackendDAE.Var inVar;
  input DAE.VarDirection inDir;
  output BackendDAE.Var var;
  output DAE.VarDirection dir;
algorithm
  var := setVarDirection(inVar, inDir);
  dir := inDir;
end setVarDirectionTpl;

public function setVarDirection "author: lochel
  Sets the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  input DAE.VarDirection inVarDirection;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef cr;
  BackendDAE.VarKind kind;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<DAE.Exp> bind;
  Option<Values.Value> v;
  list<DAE.Dimension> dim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  BackendDAE.Var oVar;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=cr,
                 varKind=kind,
                 varParallelism=prl,
                 varType=tp,
                 bindExp=bind,
                 bindValue=v,
                 arryDim=dim,
                 source=source,
                 values=attr,
                 tearingSelectOption=ts,
                 comment=comment,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  outVar := BackendDAE.VAR(cr, kind, inVarDirection, prl, tp, bind, v, dim, source, attr, ts, comment, ct, io, unreplaceable); // referenceUpdate(inVar, 3, varDirection);
end setVarDirection;

public function getVarDirection "author: wbraun
  Get the DAE.VarDirection of a variable"
  input BackendDAE.Var inVar;
  output DAE.VarDirection varDirection;
algorithm
  varDirection := match (inVar)
    case (BackendDAE.VAR(varDirection = varDirection)) then  varDirection;
  end match;
end getVarDirection;

public function getVarNominalValue "
  Returns the DAE.NominalValue or default value of a variable."
  input BackendDAE.Var InVar;
  output DAE.Exp nom;
algorithm
  nom := match(InVar)
         local Option<DAE.VariableAttributes> attr;
           case(BackendDAE.VAR(values = attr)) then DAEUtil.getNominalAttr(attr);
         end match;
end getVarNominalValue;

public function getVarKind "
  Get the DAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  output BackendDAE.VarKind varKind;
algorithm
  varKind := match (inVar)
    case (BackendDAE.VAR(varKind = varKind)) then  varKind;
  end match;
end getVarKind;

public function getVarKindForVar"fetch the varkind for an indexed var inside the variable-array."
  input Integer idx;
  input BackendDAE.Variables varsIn;
  output BackendDAE.VarKind kind;
protected
  BackendDAE.Var var;
algorithm
  var := getVarAt(varsIn,idx);
  kind := getVarKind(var);
end getVarKindForVar;

public function isVarOnTopLevelAndOutput "and has the DAE.VarDirection = OUTPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match(inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,connectorType = ct))
      then topLevelOutput(cr, dir, ct);
  end match;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput "and has the DAE.VarDirection = INPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  match (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,connectorType = ct))
      then topLevelInput(cr, dir, ct);
  end match;
end isVarOnTopLevelAndInput;

public function isVarOnTopLevelAndInputNoDerInput
    input BackendDAE.Var inVar;
    output Boolean outBoolean = isVarOnTopLevelAndInput(inVar) and not isRealOptimizeDerInput(inVar);
end isVarOnTopLevelAndInputNoDerInput;

public function topLevelInput "author: PA
  Succeds if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output Boolean outTopLevelInput;
algorithm
  outTopLevelInput := match (inComponentRef,inVarDirection,inConnectorType)
    case (DAE.CREF_IDENT(), DAE.INPUT(), _) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT()), DAE.INPUT(), DAE.FLOW()) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT()), DAE.INPUT(), DAE.POTENTIAL()) then true;
    else false;
  end match;
end topLevelInput;

protected function topLevelOutput
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output Boolean outTopLevelOutput;
algorithm
  outTopLevelOutput := match(inComponentRef, inVarDirection, inConnectorType)
    case (DAE.CREF_IDENT(), DAE.OUTPUT(), _) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT()), DAE.OUTPUT(), DAE.FLOW()) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT()), DAE.OUTPUT(), DAE.POTENTIAL()) then true;
    else false;
  end match;
end topLevelOutput;


public function isFinalVar "author: Frenkel TUD
  Returns true if var is final."
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        b=DAEUtil.getFinalAttr(attr);
      then b;
   end match;
end isFinalVar;

public function isFinalOrProtectedVar
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        b = DAEUtil.getFinalAttr(attr) or DAEUtil.getProtectedAttr(attr);
      then b;
   end match;
end isFinalOrProtectedVar;

public function getVariableAttributes "author: Frenkel TUD 2011-04
  returns the DAE.VariableAttributes of a variable"
  input BackendDAE.Var inVar;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match (inVar)
    local
      Option<DAE.VariableAttributes> attr;
    case BackendDAE.VAR(values = attr) then attr;
  end match;
end getVariableAttributes;

public function getVarSource "author: Frenkel TUD 2011-04
  returns the DAE.ElementSource of a variable"
  input BackendDAE.Var inVar;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (inVar)
    local
      DAE.ElementSource source;
    case BackendDAE.VAR(source = source) then source;
  end match;
end getVarSource;

public function getVarType "author: marcusw
  returns the BackendDAE.Type of the variable"
  input BackendDAE.Var inVar;
  output BackendDAE.Type outType;
algorithm
  outType := match (inVar)
    local
      BackendDAE.Type varType;
    case BackendDAE.VAR(varType=varType) then varType;
  end match;
end getVarType;

public function getMinMaxAsserts "author: Frenkel TUD 2011-03"
  input BackendDAE.Var inVar;
  input list<DAE.Algorithm> inAsserts;
  output BackendDAE.Var outVar = inVar;
  output list<DAE.Algorithm> outAsserts;
algorithm
  outAsserts := matchcontinue(inVar)
    local
      DAE.Exp e, cond, msg;
      list<Option<DAE.Exp>> minmax;
      String str, format;
      DAE.Type tp;
      DAE.ComponentRef name;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Type varType;
      DAE.ElementSource source;

    case BackendDAE.VAR(varKind=BackendDAE.CONST())
    then inAsserts;

    case BackendDAE.VAR(varName=name, values=attr, varType=varType, source=source) equation
      minmax = DAEUtil.getMinMax(attr);
      e = Expression.crefExp(name);
      tp = BackendDAEUtil.makeExpType(varType);

      // do not add if const true
      cond = getMinMaxAsserts1(minmax, e, tp);
      (cond, _) = ExpressionSimplify.simplify(cond);
      false = Expression.isConstTrue(cond);

      str = "Variable " + ComponentReference.printComponentRefStr(name) + " out of [min, max] interval: ";
      str = str + ExpressionDump.printExpStr(cond) + " has value: ";
      // if is real use %g otherwise use %d (ints and enums)
      format = if Types.isRealOrSubTypeReal(tp) then "g" else "d";
      msg = DAE.BINARY(DAE.SCONST(str), DAE.ADD(DAE.T_STRING_DEFAULT), DAE.CALL(Absyn.IDENT("String"), {e, DAE.SCONST(format)}, DAE.callAttrBuiltinString));
      BackendDAEUtil.checkAssertCondition(cond, msg, DAE.ASSERTIONLEVEL_WARNING, DAEUtil.getElementSourceFileInfo(source));
    then DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond, msg, DAE.ASSERTIONLEVEL_WARNING, source)})::inAsserts;

    else inAsserts;
  end matchcontinue;
end getMinMaxAsserts;

protected function getMinMaxAsserts1 "author: Frenkel TUD 2011-03"
  input list<Option<DAE.Exp>> ominmax;
  input DAE.Exp e;
  input DAE.Type tp;
  output DAE.Exp cond;
algorithm
  cond :=
  match (ominmax,e,tp)
    local
      DAE.Exp min,max;
    case (SOME(min)::(SOME(max)::{}),_,_)
      then DAE.LBINARY(DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE()),
                            DAE.AND(DAE.T_BOOL_DEFAULT),
                            DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE()));
    case (SOME(min)::(NONE()::{}),_,_)
      then DAE.RELATION(e,DAE.GREATEREQ(tp),min,-1,NONE());
    case (NONE()::(SOME(max)::{}),_,_)
      then DAE.RELATION(e,DAE.LESSEQ(tp),max,-1,NONE());
  end match;
end getMinMaxAsserts1;

public function getNominalAssert "author: Frenkel TUD 2011-03"
  input BackendDAE.Var inVar;
  input list<DAE.Algorithm> inAsserts;
  output BackendDAE.Var outVar = inVar;
  output list<DAE.Algorithm> outAsserts;
algorithm
  outAsserts := matchcontinue(inVar)
    local
      DAE.Exp e, cond, msg;
      list<Option<DAE.Exp>> minmax;
      String str, format;
      DAE.Type tp;
      DAE.ComponentRef name;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Type varType;
      DAE.ElementSource source;

    case BackendDAE.VAR(varKind=BackendDAE.CONST())
    then inAsserts;

    case BackendDAE.VAR(varName=name,  values=attr as SOME(DAE.VAR_ATTR_REAL(nominal=SOME(e))), varType=varType,  source=source) equation
      minmax = DAEUtil.getMinMax(attr);
      tp = BackendDAEUtil.makeExpType(varType);

      // do not add if const true
      cond = getMinMaxAsserts1(minmax, e, tp);
      (cond, _) = ExpressionSimplify.simplify(cond);
      false = Expression.isConstTrue(cond);

      str = "Nominal " + ComponentReference.printComponentRefStr(name) + " out of [min,  max] interval: ";
      str = str + ExpressionDump.printExpStr(cond) + " has value: ";
      // if is real use %g otherwise use %d (ints and enums)
      format = if Types.isRealOrSubTypeReal(tp) then "g" else "d";
      msg = DAE.BINARY(DAE.SCONST(str), DAE.ADD(DAE.T_STRING_DEFAULT), DAE.CALL(Absyn.IDENT("String"), {e,  DAE.SCONST(format)}, DAE.callAttrBuiltinString));
      BackendDAEUtil.checkAssertCondition(cond, msg, DAE.ASSERTIONLEVEL_WARNING, DAEUtil.getElementSourceFileInfo(source));
    then DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond, msg, DAE.ASSERTIONLEVEL_WARNING, source)})::inAsserts;

    else inAsserts;
  end matchcontinue;
end getNominalAssert;

public function varSortFunc "A sorting function (greatherThan) for Variables based on crefs"
  input BackendDAE.Var v1;
  input BackendDAE.Var v2;
  output Boolean greaterThan;
algorithm
  greaterThan := ComponentReference.crefSortFunc(varCref(v1), varCref(v2));
end varSortFunc;


public function getAlias
"  author: Frenkel TUD 2012-11
  returns the original Varname of an AliasVar"
  input BackendDAE.Var inVar;
  output DAE.ComponentRef outCr;
  output Boolean negated;
protected
  DAE.Exp e;
algorithm
  e := varBindExp(inVar);
  (outCr,negated) := getAlias1(e);
end getAlias;

protected function getAlias1
  input DAE.Exp inExp;
  output DAE.ComponentRef outCr;
  output Boolean negated;
algorithm
  (outCr,negated) :=
  match (inExp)
    local
      DAE.ComponentRef name;

    case DAE.CREF(componentRef=name) then (name, false);
    case DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.LUNARY(operator=DAE.NOT(_),exp=DAE.CREF(componentRef=name)) then (name,true);
    case DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)})
      equation
        name = ComponentReference.crefPrefixDer(name);
      then (name, false);
    case DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)}))
      equation
       name = ComponentReference.crefPrefixDer(name);
    then (name,true);
    case DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=name)}))
      equation
       name = ComponentReference.crefPrefixDer(name);
    then (name,true);
  end match;
end getAlias1;

public function daenumVariables
  input BackendDAE.EqSystem syst;
  output Integer n;
protected
 BackendDAE.Variables vars;
algorithm
  vars := daeVars(syst);
  n := varsSize(vars);
end daenumVariables;

/* =======================================================
 *
 *  Section for functions that deals with VariablesArray
 *
 * =======================================================
 */

protected function copyArray
  "Makes a copy of a variable array."
  input BackendDAE.VariableArray inArray;
  output BackendDAE.VariableArray outArray;
protected
  Integer num_elems, size;
  array<Option<BackendDAE.Var>> vars;
algorithm
  BackendDAE.VARIABLE_ARRAY(num_elems, size, vars) := inArray;
  vars := arrayCopy(vars);
  outArray := BackendDAE.VARIABLE_ARRAY(num_elems, size, vars);
end copyArray;

protected function vararrayEmpty
  input Integer inSize;
  output BackendDAE.VariableArray outArray;
protected
  array<Option<BackendDAE.Var>> arr;
algorithm
  arr := arrayCreate(inSize, NONE());
  outArray := BackendDAE.VARIABLE_ARRAY(0, inSize, arr);
end vararrayEmpty;

protected function vararrayAdd
"author: PA
  Adds a variable last to the BackendDAE.VariableArray, increasing array size
  if no space left by factor 1.4"
  input BackendDAE.VariableArray inVariableArray;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
protected
  Integer num_elems, size;
  array<Option<BackendDAE.Var>> arr;
algorithm
  BackendDAE.VARIABLE_ARRAY(num_elems, size, arr) := inVariableArray;
  num_elems := num_elems + 1;
  arr := Array.expandOnDemand(num_elems, arr, 1.4, NONE());
  size := arrayLength(arr);
  arrayUpdate(arr, num_elems, SOME(inVar));
  outVariableArray := BackendDAE.VARIABLE_ARRAY(num_elems, size, arr);
end vararrayAdd;

protected function vararraySetnth
  "Sets the n:th variable in the array."
  input BackendDAE.VariableArray inVariableArray;
  input Integer inIndex;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
protected
  array<Option<BackendDAE.Var>> arr;
  Integer num_elems, size;
algorithm
  BackendDAE.VARIABLE_ARRAY(num_elems, size, arr) := inVariableArray;
  true := inIndex <= num_elems;
  arrayUpdate(arr, inIndex, SOME(inVar));
  outVariableArray := BackendDAE.VARIABLE_ARRAY(num_elems, size, arr);
end vararraySetnth;

protected function vararrayNth
  "Returns the n:th variable in the array."
  input BackendDAE.VariableArray inVariableArray;
  input Integer inIndex;
  output BackendDAE.Var outVar;
protected
  array<Option<BackendDAE.Var>> arr;
  Integer num_elems;
algorithm
  BackendDAE.VARIABLE_ARRAY(numberOfElements = num_elems, varOptArr = arr) := inVariableArray;
  true := inIndex <= num_elems;
  SOME(outVar) := arr[inIndex];
end vararrayNth;

protected function vararrayDelete
  input BackendDAE.VariableArray inVariableArray;
  input Integer inIndex;
  output BackendDAE.VariableArray outVariableArray;
  output BackendDAE.Var outVar;
protected
  Integer num_elems, arr_size;
  array<Option<BackendDAE.Var>> arr;
algorithm
  BackendDAE.VARIABLE_ARRAY(num_elems, arr_size, arr) := inVariableArray;
  SOME(outVar) := arr[inIndex];
  arrayUpdate(arr, inIndex, NONE());
  outVariableArray := BackendDAE.VARIABLE_ARRAY(num_elems, arr_size, arr);
end vararrayDelete;

protected function vararrayList
  "Returns a list of all the variables in the variable array."
  input BackendDAE.VariableArray inArray;
  output list<BackendDAE.Var> outVars = {};
protected
  Integer num_elems;
  array<Option<BackendDAE.Var>> arr;
  BackendDAE.Var var;
  Option<BackendDAE.Var> ovar;
algorithm
  BackendDAE.VARIABLE_ARRAY(numberOfElements = num_elems, varOptArr = arr) := inArray;

  for i in num_elems:-1:1 loop
    ovar := arr[i];
    if isSome(ovar) then
      SOME(var) := ovar;
      outVars := var :: outVars;
    end if;
  end for;
end vararrayList;

/* =======================================================
 *
 *  Section for functions that deals with Variables
 *
 * =======================================================
 */

public function copyVariables
  "Makes a copy of a Variables."
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
protected
  array<list<BackendDAE.CrefIndex>> indices;
  BackendDAE.VariableArray varArr;
  Integer buckets, num_vars, num_elems, arr_size;
  array<Option<BackendDAE.Var>> varOptArr;
algorithm
  BackendDAE.VARIABLES(indices, varArr, buckets, num_vars) := inVariables;
  indices := arrayCopy(indices);
  varArr := copyArray(varArr);
  outVariables := BackendDAE.VARIABLES(indices, varArr, buckets, num_vars);
end copyVariables;

public function emptyVars
  "Creates a new empty Variable structure."
  input Integer inSize = BaseHashTable.bigBucketSize;
  output BackendDAE.Variables outVariables;
protected
  array<list<BackendDAE.CrefIndex>> indices;
  Integer buckets, arr_size;
  BackendDAE.VariableArray arr;
algorithm
  arr_size := max(inSize, BaseHashTable.lowBucketSize);
  buckets := realInt(intReal(arr_size) * 1.4);
  indices := arrayCreate(buckets, {});
  arr := vararrayEmpty(arr_size);
  outVariables := BackendDAE.VARIABLES(indices, arr, buckets, 0);
end emptyVars;

public function emptyVarsSized
  "Returns a Variable datastructure that is empty."
  input Integer size;
  output BackendDAE.Variables outVariables = emptyVars(size);
end emptyVarsSized;

public function varList
  "Takes a BackendDAE.Variables and returns a list of all variables in it,
   useful for e.g. dumping.

   NOTE: This function will fail if the Variables contains more than one set.
     This is because mergeVariables doesn't do a real merging, so if we just
     append all the variables from the sets we might get duplicates."
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
protected
  BackendDAE.VariableArray arr;
algorithm
  BackendDAE.VARIABLES(varArr = arr) := inVariables;
  outVarLst := vararrayList(arr);
end varList;

public function listVar
"author: PA
  Takes Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
protected
  Integer size;
algorithm
  size := listLength(inVarLst);
  outVariables := emptyVarsSized(size);
  outVariables := addVars(listReverse(inVarLst), outVariables);
end listVar;

public function listVarSized "author: Frenkel TUD 2012-05
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  input Integer size;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold(inVarLst,addVar,emptyVarsSized(size));
end listVarSized;

public function listVar1 "author: Frenkel TUD 2012-05
  ToDo: replace all listVar calls with this function, tailrecursive implementation
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
protected
  Integer size;
algorithm
  size := listLength(inVarLst);
  outVariables := List.fold(inVarLst,addVar,emptyVarsSized(size));
end listVar1;

public function equationSystemsVarsLst
  input BackendDAE.EqSystems systs;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match (systs,inVars)
    local
      BackendDAE.EqSystems rest;
      list<BackendDAE.Var> vars,vars1;
      BackendDAE.Variables v;
      case ({},_) then inVars;
      case (BackendDAE.EQSYSTEM(orderedVars = v)::rest,_)
        equation
          vars = varList(v);
          vars1 = listAppend(inVars,vars);
        then
          equationSystemsVarsLst(rest,vars1);
    end match;
end equationSystemsVarsLst;


public function daeVars
  input BackendDAE.EqSystem syst;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = vars) := syst;
end daeVars;

public function daeKnVars
  input BackendDAE.Shared shared;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(knownVars = vars) := shared;
end daeKnVars;

public function daeAliasVars
  input BackendDAE.Shared shared;
  output BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(aliasVars = vars) := shared;
end daeAliasVars;

public function varsSize
  "Returns the number of variables in the Variables structure."
  input BackendDAE.Variables inVariables;
  output Integer outNumVariables;
algorithm
  BackendDAE.VARIABLES(varArr=BackendDAE.VARIABLE_ARRAY(numberOfElements=outNumVariables)) := inVariables;
end varsSize;

protected function varsLoadFactor
  input BackendDAE.Variables inVariables;
  input Integer inIncrease = 0;
  output Real outLoadFactor;
protected
  Integer buckets, num_vars;
algorithm
  BackendDAE.VARIABLES(bucketSize = buckets, numberOfVars = num_vars) := inVariables;
  num_vars := num_vars + inIncrease;
  outLoadFactor := intReal(num_vars) / buckets;
end varsLoadFactor;

public function isVariable
"
  This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
algorithm
  _:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
      BackendDAE.VarKind kind;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, vars);
        isVarKindVariable(kind);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, knvars);
        isVarKindVariable(kind);
      then
        ();
  end matchcontinue;
end isVariable;

public function isVarKindVariable "This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input BackendDAE.VarKind inVarKind;
algorithm
  _:=
  match (inVarKind)
    case (BackendDAE.VARIABLE()) then ();
    case (BackendDAE.STATE()) then ();
    case (BackendDAE.DUMMY_STATE()) then ();
    case (BackendDAE.DUMMY_DER()) then ();
    case (BackendDAE.DISCRETE()) then ();
  end match;
end isVarKindVariable;

public function isTopLevelInputOrOutput "author: LP

  This function checks if the provided cr is from a var that is on top model
  and is an input or an output, and returns true for such variables.
  It also returns true for input/output connector variables, i.e. variables
  instantiated from a  connector class, that are instantiated on the top level.
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1.
  Note: The function needs the known variables to search for input variables
  on the top level.
  inputs:  (cref: DAE.ComponentRef,
              vars: Variables, /* BackendDAE.Variables */
              knownVars: BackendDAE.Variables /* Known BackendDAE.Variables */)
  outputs: bool"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varName = DAE.CREF_IDENT(), varDirection = DAE.OUTPUT()) :: _),_) = getVar(cr, vars);
      then
        true;
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varDirection = DAE.INPUT()) :: _),_) = getVar(cr, knvars) "input variables stored in known variables are input on top level";
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
end isTopLevelInputOrOutput;

public function deleteCrefs "author: wbraun
  Removes a list of DAE.ComponentRef from BackendDAE.Variables"
  input list<DAE.ComponentRef> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, removeCref, vars);
  vars_1 := listVar1(varList(vars_1));
end deleteCrefs;

public function deleteVars "author: Frenkel TUD 2011-04
  Deletes variables from Variables. This is an expensive operation
  since we need to create a new binary tree with new indexes as well
  as a new compacted vector of variables."
  input BackendDAE.Variables inDelVars;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inDelVars,inVariables)
    local
      BackendDAE.Variables newvars;
    case (_,_)
      equation
        true = intGt(varsSize(inDelVars),0);
        newvars = traverseBackendDAEVars(inDelVars,deleteVars1,inVariables);
        newvars = listVar1(varList(newvars));
      then
        newvars;
    else
      then
        inVariables;
  end matchcontinue;
end deleteVars;

protected function deleteVars1
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  output BackendDAE.Var v;
  output BackendDAE.Variables vars;
protected
  DAE.ComponentRef cr;
algorithm
  v := inVar;
  BackendDAE.VAR(varName = cr) := v;
  vars := removeCref(cr,inVars);
end deleteVars1;

public function deleteVar
"author: PA
  Deletes a variable from Variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := match(inComponentRef,inVariables)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<Integer> ilst;

    case (cr,_) equation
      (_,ilst) = getVar(cr,inVariables);
      (vars,_) = removeVars(ilst,inVariables,{});
      vars = listVar1(varList(vars));
    then vars;
  end match;
end deleteVar;

public function removeCrefs "author: wbraun
  Removes a list of DAE.ComponentRef from BackendDAE.Variables"
  input list<DAE.ComponentRef> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
algorithm
  vars_1 := List.fold(varlst, removeCref, vars);
end removeCrefs;

public function removeCref
"author: Frenkel TUD 2012-09
  Deletes a variable from Variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<Integer> ilst;
    case (cr,_)
      equation
        (_,ilst) = getVar(cr,inVariables);
        (vars,_) = removeVars(ilst,inVariables,{});
      then
        vars;
    else inVariables;
  end matchcontinue;
end removeCref;

public function removeVars "author: Frenkel TUD 2012-09
  Removes vars from the vararray but does not scaling down the array"
  input list<Integer> inVarPos "Position of vars to delete 1 based";
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Var> iAcc;
  output BackendDAE.Variables outVariables;
  output list<BackendDAE.Var> outVars "deleted vars in reverse order";
algorithm
  (outVariables,outVars) := matchcontinue(inVarPos,inVariables,iAcc)
    local
      BackendDAE.Variables vars;
      list<Integer> ilst;
      Integer i;
      BackendDAE.Var v;
      list<BackendDAE.Var> acc;
    case({},_,_) then (inVariables,iAcc);
    case(i::ilst,_,_)
      equation
        (vars,v) = removeVar(i,inVariables);
        (vars,acc) = removeVars(ilst,vars,v::iAcc);
      then
        (vars,acc);
    case(_::ilst,_,_)
      equation
        (vars,acc) = removeVars(ilst,inVariables,iAcc);
      then
        (vars,acc);
  end matchcontinue;
end removeVars;

public function removeVarDAE
"author: Frenkel TUD 2012-11
  Removes a var from the vararray but does not scaling down the array"
  input Integer inVarPos "1 based index";
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Var outVar;
algorithm
  (osyst,outVar) := match (inVarPos,syst)
    local
      BackendDAE.Var var;
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets=stateSets,partitionKind=partitionKind))
      equation
        (ordvars1,outVar) = removeVar(inVarPos,ordvars);
      then (BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching,stateSets,partitionKind),outVar);
  end match;
end removeVarDAE;

public function removeAliasVars
"
remove alias Vars
"
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
      BackendDAE.Variables knvars, exobj, aliasVars;
      BackendDAE.EquationArray remeqns, inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;
algorithm
  (BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei)) := inShared;
  aliasVars := emptyVars();
  outShared := BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei);

end removeAliasVars;

public function removeVar
  "Removes a var from the vararray but does not scaling down the array"
  input Integer inIndex;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Var outVar;
protected
  array<list<BackendDAE.CrefIndex>> indices;
  list<BackendDAE.CrefIndex> cr_indices;
  BackendDAE.VariableArray arr;
  Integer buckets, num_vars, hash_idx;
  DAE.ComponentRef cr;
algorithm
  BackendDAE.VARIABLES(indices, arr, buckets, num_vars) := inVariables;
  (arr, outVar as BackendDAE.VAR(varName = cr)) := vararrayDelete(arr, inIndex);
  hash_idx := ComponentReference.hashComponentRefMod(cr, buckets) + 1;
  cr_indices := indices[hash_idx];
  cr_indices := List.deleteMemberOnTrue(BackendDAE.CREFINDEX(cr, inIndex - 1),
    cr_indices, removeVar2);
  arrayUpdate(indices, hash_idx, cr_indices);
  outVariables := BackendDAE.VARIABLES(indices, arr, buckets, num_vars);
end removeVar;

protected function removeVar2
  input BackendDAE.CrefIndex inCrefIndex1;
  input BackendDAE.CrefIndex inCrefIndex2;
  output Boolean outMatch;
protected
  Integer i1, i2;
algorithm
  BackendDAE.CREFINDEX(index = i1) := inCrefIndex1;
  BackendDAE.CREFINDEX(index = i2) := inCrefIndex2;
  outMatch := i1 == i2;
end removeVar2;

public function existsVar
"author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  input Boolean skipDiscrete;
  output Boolean outExists;
protected
  list<BackendDAE.Var> varlst;
algorithm
  try
    varlst := getVar(inComponentRef, inVariables);
    varlst := if skipDiscrete then List.select(varlst, isVarNonDiscrete) else varlst;
    outExists := not listEmpty(varlst);
  else
    outExists := false;
  end try;
end existsVar;

public function makeVar
 input DAE.ComponentRef cr;
 output BackendDAE.Var v = BackendDAE.VAR(cr, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
end makeVar;

public function addVarDAE
"author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inVar,syst)
    local
      BackendDAE.Variables ordvars,ordvars1;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets,partitionKind))
      equation
        ordvars1 = addVar(inVar,ordvars);
      then BackendDAE.EQSYSTEM(ordvars1,eqns,m,mT,matching,stateSets,partitionKind);
  end match;
end addVarDAE;

public function addKnVarDAE
"author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Variables knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei))
      equation
        knvars1 = addVar(inVar,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei);

  end match;
end addKnVarDAE;

public function addNewKnVarDAE
"author: Frenkel TUD 2011-04
  Add a variable to Variables of a BackendDAE.
  No Check if variable already exist. Use only for new variables"
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Variables knvars,exobj,knvars1,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei))
      equation
        knvars1 = addNewVar(inVar,knvars);
      then BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei);

  end match;
end addNewKnVarDAE;

public function addAliasVarDAE
"author: Frenkel TUD 2012-09
  Add a alias variable to Variables of a BackendDAE.Shared
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei))
      equation
        aliasVars = addVar(inVar,aliasVars);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei);

  end match;
end addAliasVarDAE;

public function addNewAliasVarDAE
"author: Frenkel TUD 2012-09
  Add a alias variable to Variables of a BackendDAE.Shared
  No Check if variable already exist. Use only for new variables"
  input BackendDAE.Var inVar;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inVar,shared)
    local
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei))
      equation
        aliasVars = addNewVar(inVar,aliasVars);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,graph,funcs,einfo,eoc,btp,symjacs,ei);

  end match;
end addNewAliasVarDAE;

public function addVar
  "Adds a variable to the set, or updates it if it already exists."
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
protected
  DAE.ComponentRef cr, cr2;
  array<list<BackendDAE.CrefIndex>> hashvec;
  BackendDAE.VariableArray varr;
  Integer bsize, num_vars, hash_idx, arr_idx;
  list<BackendDAE.CrefIndex> indices;
algorithm
  BackendDAE.VAR(varName = cr) := inVar;
  BackendDAE.VARIABLES(hashvec, varr, bsize, num_vars) := inVariables;

  hash_idx := ComponentReference.hashComponentRefMod(cr, bsize) + 1;
  indices := hashvec[hash_idx];

  try
    BackendDAE.CREFINDEX(index = arr_idx) :=
      List.getMemberOnTrue(cr, indices, crefIndexEqualCref);
    varr := vararraySetnth(varr, arr_idx + 1, inVar);
  else
    varr := vararrayAdd(varr, inVar);
    arrayUpdate(hashvec, hash_idx, (BackendDAE.CREFINDEX(cr, num_vars) :: indices));
    num_vars := num_vars + 1;
  end try;

  outVariables := BackendDAE.VARIABLES(hashvec, varr, bsize, num_vars);
end addVar;

public function addVars
  "Adds a list of variables to the Variables structure. If any variable already
   exists it's updated instead."
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold(inVars, addVar, inVariables);
end addVars;

public function addNewVar
  "Add a new variable to the set, without checking if it already exists."
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
protected
  DAE.ComponentRef cr;
  array<list<BackendDAE.CrefIndex>> hashvec;
  BackendDAE.VariableArray varr;
  Integer bsize, num_vars, idx;
  list<BackendDAE.CrefIndex> indices;
algorithm
  BackendDAE.VAR(varName = cr) := inVar;
  BackendDAE.VARIABLES(hashvec, varr, bsize, num_vars) := inVariables;
  idx := ComponentReference.hashComponentRefMod(cr, bsize) + 1;
  varr := vararrayAdd(varr, inVar);
  indices := hashvec[idx];
  arrayUpdate(hashvec, idx, (BackendDAE.CREFINDEX(cr, num_vars) :: indices));
  outVariables := BackendDAE.VARIABLES(hashvec, varr, bsize, num_vars + 1);
end addNewVar;

public function addVariables
  "Adds the content of one Variables to another."
  input BackendDAE.Variables inSrcVars;
  input BackendDAE.Variables inDestVars;
  output BackendDAE.Variables outVars = inDestVars;
protected
  array<Option<BackendDAE.Var>> vars;
  Integer num_vars;
  BackendDAE.Var var;
  Option<BackendDAE.Var> ovar;
algorithm
  // TODO: Don't rehash if the sets have the same size!
  BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(
    numberOfElements = num_vars, varOptArr = vars)) := inSrcVars;

  for i in 1:num_vars loop
    ovar := vars[i];
    if isSome(ovar) then
      SOME(var) := ovar;
      outVars := addVar(var, outVars);
    end if;
  end for;
end addVariables;

public function getVarAt
  "Returns the variable at a given position."
  input BackendDAE.Variables inVariables;
  input Integer inIndex;
  output BackendDAE.Var outVar;
protected
  BackendDAE.VariableArray arr;
algorithm
  BackendDAE.VARIABLES(varArr=arr) := inVariables;
  outVar := vararrayNth(arr, inIndex);
end getVarAt;

public function setVarAt
  input BackendDAE.Variables inVariables;
  input Integer inIndex;
  input BackendDAE.Var inVar;
  output BackendDAE.Variables outVariables = inVariables;
protected
  BackendDAE.VariableArray arr;
algorithm
  BackendDAE.VARIABLES(varArr = arr) := inVariables;
  vararraySetnth(arr, inIndex, inVar);
end setVarAt;

public function getVarAtIndexFirst
"author: marcusw
  Return variable at a given position, enumerated from 1..n, but with the index as first argument, so that it can be used with fold an map functions."
  input Integer inIndex;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Var outVar;
algorithm
  outVar := getVarAt(inVariables, inIndex);
end getVarAtIndexFirst;

public function getVarSharedAt
"author: Frenkel TUD 2012-12
  return a Variable."
  input Integer inInteger;
  input BackendDAE.Shared shared;
  output BackendDAE.Var outVar;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.SHARED(knownVars=vars) := shared;
  outVar := getVarAt(vars,inInteger);
end getVarSharedAt;

public function getVarDAE
"author: Frenkel TUD 2012-05
  return a Variable."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.EqSystem syst;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := match (inComponentRef,syst)
    local
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Integer> indxlst;
   case (_,BackendDAE.EQSYSTEM(orderedVars=vars))
      equation
        (varlst,indxlst) = getVar(inComponentRef,vars);
      then
        (varlst,indxlst);
  end match;
end getVarDAE;

public function getVarShared
"author: Frenkel TUD 2012-05
  return a Variable."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Shared shared;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := match (inComponentRef,shared)
    local
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Integer> indxlst;
   case (_,BackendDAE.SHARED(knownVars=vars))
      equation
        (varlst,indxlst) = getVar(inComponentRef,vars);
      then
        (varlst,indxlst);
  end match;
end getVarShared;

public function getVar
"author: PA
  Return a variable(s) and its index(es) in the vector.
  The indexes is enumerated from 1..n
  Normally a variable has only one index, but in case of an array variable
  it may have several indexes and several scalar variables,
  therefore a list of variables and a list of  indexes is returned.
  inputs:  (DAE.ComponentRef, BackendDAE.Variables)
  outputs: (Var list, int list /* indexes */)"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (cr,inVariables)
    local
      BackendDAE.Var v;
      Integer indx;
      list<Integer> indxs;
      list<BackendDAE.Var> vLst;
      list<DAE.ComponentRef> crlst;
      DAE.ComponentRef cr1;
    case (_,_)
      equation
        (v,indx) = getVar2(cr, inVariables) "if scalar found, return it";
      then
        ({v},{indx});
    case (_,_) /* check if array or record */
      equation
        crlst = ComponentReference.expandCref(cr,true);
        (vLst as _::_,indxs) = getVarLst(crlst,inVariables,{},{});
      then
        (vLst,indxs);
    // try again check if variable indexes used
    case (_,_)
      equation
        // replace variables with WHOLEDIM()
        (cr1,true) = replaceVarWithWholeDim(cr, false);
        crlst = ComponentReference.expandCref(cr1,true);
        (vLst as _::_,indxs) = getVarLst(crlst,inVariables,{},{});
      then
        (vLst,indxs);
    /* failure
    case (_,_)
      equation
        fprintln(Flags.DAE_LOW, "- getVar failed on component reference: " + ComponentReference.printComponentRefStr(cr));
      then
        fail();
     */
  end matchcontinue;
end getVar;

protected function replaceVarWithWholeDim
  "Helper function to traverseExp. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input DAE.ComponentRef inCref;
  input Boolean iPerformed;
  output DAE.ComponentRef outCref;
  output Boolean oPerformed;
algorithm
  (outCref, oPerformed) := match(inCref, iPerformed)
    local
      DAE.Ident name;
      DAE.ComponentRef cr,cr_1;
      DAE.Type ty;
      list<DAE.Subscript> subs,subs_1;
      Boolean b;

    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), _)
      equation
        (subs_1, b) = replaceVarWithWholeDimSubs(subs, iPerformed);
        (cr_1, b) = replaceVarWithWholeDim(cr, b);
      then
        (DAE.CREF_QUAL(name, ty, subs_1, cr_1), b);

    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), _)
      equation
        (subs_1, b) = replaceVarWithWholeDimSubs(subs, iPerformed);
      then
        (DAE.CREF_IDENT(name, ty, subs_1), b);

    case (DAE.CREF_ITER(), _) then (inCref, iPerformed);
    case (DAE.OPTIMICA_ATTR_INST_CREF(), _) then (inCref, iPerformed);
    case (DAE.WILD(), _) then (inCref, iPerformed);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendVariable.replaceVarWithWholeDim: Unknown cref"});
      then fail();
  end match;
end replaceVarWithWholeDim;

protected function replaceVarWithWholeDimSubs
  input list<DAE.Subscript> inSubscript;
  input Boolean iPerformed;
  output list<DAE.Subscript> outSubscript;
  output Boolean oPerformed;
algorithm
  (outSubscript, oPerformed) := match(inSubscript, iPerformed)
    local
      DAE.Exp sub_exp;
      list<DAE.Subscript> rest,res;
      Boolean b,const,calcRange;

    case ({}, _) then (inSubscript,iPerformed);
    case (DAE.WHOLEDIM()::rest, _)
      equation
        (_,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
      then (DAE.WHOLEDIM()::rest, b);

    case (DAE.SLICE(exp = sub_exp)::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = if const then DAE.SLICE(sub_exp)::rest else (DAE.WHOLEDIM()::rest);
      then
        (res, b or not const);

    case (DAE.INDEX(exp = sub_exp)::rest, _)
      equation
        (sub_exp,calcRange) = computeRangeExps(sub_exp); // the fact that if it can be calculated, we can take the wholedim is a bit weird, anyway, the whole function is weird
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = if const then DAE.INDEX(sub_exp)::rest else (DAE.WHOLEDIM()::rest);
      then
        (res, b or not const or calcRange);
    case (DAE.WHOLE_NONEXP(exp = sub_exp)::rest, _)
      equation
        (res,b) = replaceVarWithWholeDimSubs(rest,iPerformed);
        const = Expression.isConst(sub_exp);
        res = if const then DAE.WHOLE_NONEXP(sub_exp)::rest else (DAE.WHOLEDIM()::rest);
      then
        (res, b or not const);
  end match;
end replaceVarWithWholeDimSubs;

protected function computeRangeExps"computes the maximal range expression for calculated ranges like [i1+i2]."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean isCalculated;
algorithm
  (outExp,isCalculated) := matchcontinue(inExp)
    local
      Integer stop1,stop2;
      DAE.Exp exp;
      DAE.Type ty;
  case(DAE.BINARY(exp1=DAE.RANGE(ty=ty,start=DAE.ICONST(integer=1),stop=DAE.ICONST(integer=stop1)), operator=DAE.ADD(), exp2=DAE.RANGE(start=DAE.ICONST(integer=1),stop=DAE.ICONST(integer=stop2))))
    equation
      stop2= stop1+stop2;
      exp = DAE.RANGE(ty,DAE.ICONST(1),NONE(),DAE.ICONST(stop2));
    then (exp,true);
   else
     then (inExp, false);
  end matchcontinue;
end computeRangeExps;

public function getVarLst
  input list<DAE.ComponentRef> inComponentRefLst;
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Var> iVarLst;
  input list<Integer> iIntegerLst;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue(inComponentRefLst,inVariables,iVarLst,iIntegerLst)
    local
      list<DAE.ComponentRef> crlst;
      DAE.ComponentRef cr;
      list<BackendDAE.Var> varlst;
      list<Integer> ilst;
      BackendDAE.Var v;
      Integer indx;
    case ({},_,_,_) then (iVarLst,iIntegerLst);
    case (cr::crlst,_,_,_)
      equation
        (v,indx) = getVar2(cr, inVariables);
        (varlst,ilst) = getVarLst(crlst,inVariables,v::iVarLst,indx::iIntegerLst);
      then
        (varlst,ilst);
    case (_::crlst,_,_,_)
      equation
        (varlst,ilst) = getVarLst(crlst,inVariables,iVarLst,iIntegerLst);
      then
        (varlst,ilst);
  end matchcontinue;
end getVarLst;

public function getVar2
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Var outVar;
  output Integer outIndex;
protected
  array<list<BackendDAE.CrefIndex>> indices;
  BackendDAE.VariableArray arr;
  Integer buckets, hash_idx;
  list<BackendDAE.CrefIndex> cr_indices;
  DAE.ComponentRef cr;
algorithm
  BackendDAE.VARIABLES(crefIndices = indices, varArr = arr,
    bucketSize = buckets) := inVariables;
  hash_idx := ComponentReference.hashComponentRefMod(inCref, buckets) + 1;
  cr_indices := indices[hash_idx];
  BackendDAE.CREFINDEX(index = outIndex) := List.getMemberOnTrue(inCref,
    cr_indices, crefIndexEqualCref);
  outIndex := outIndex + 1;
  outVar as BackendDAE.VAR(varName = cr) := vararrayNth(arr, outIndex);
  true := ComponentReference.crefEqualNoStringCompare(cr, inCref);
end getVar2;

protected function crefIndexEqualCref
  input DAE.ComponentRef inCref;
  input BackendDAE.CrefIndex inIndex;
  output Boolean outMatch;
protected
  DAE.ComponentRef cr;
algorithm
  BackendDAE.CREFINDEX(cref = cr) := inIndex;
  outMatch := ComponentReference.crefEqualNoStringCompare(cr, inCref);
end crefIndexEqualCref;

public function getVarIndexFromVars
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Variables inVariables;
  output list<Integer> outIndices = {};
algorithm
  for var in inVars loop
    (_, outIndices) := traversingVarIndexFinder(var, inVariables, outIndices);
  end for;
end getVarIndexFromVars;

public function getVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inVariables2;
  output list<Integer> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,
    function traversingVarIndexFinder(inVars = inVariables2), {});
end getVarIndexFromVariables;

protected function traversingVarIndexFinder
"author: Frenkel TUD 2010-11"
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  input list<Integer> inIndices;
  output BackendDAE.Var outVar = inVar;
  output list<Integer> outIndices;
protected
  DAE.ComponentRef cr;
  list<Integer> indices;
algorithm
  try
    cr := varCref(inVar);
    (_, indices) := getVar(cr, inVars);
    outIndices := listAppend(inIndices, indices);
  else
    outIndices := inIndices;
  end try;
end traversingVarIndexFinder;

public function mergeVariables
  "Merges two sets of Variables, where the variables of the first set takes
   precedence over the second set."
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  output BackendDAE.Variables outVariables;
protected
  Integer num_vars;
  Integer b1, b2;
algorithm
  num_vars := varsSize(inVariables2);

  if varsLoadFactor(inVariables1, num_vars) > 1 then
    BackendDAE.VARIABLES(bucketSize = b1) := inVariables1;
    BackendDAE.VARIABLES(bucketSize = b2) := inVariables2;
    outVariables := emptyVarsSized(varsSize(inVariables1) + num_vars);
    outVariables := addVariables(inVariables1, outVariables);
  else
    outVariables := copyVariables(inVariables1);
  end if;

  outVariables := addVariables(inVariables2, outVariables);
end mergeVariables;

public function rehashVariables
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
protected
  Real load = varsLoadFactor(inVariables, 0);
algorithm
  if load < 0.5 or load > 1.0 then
    outVariables := emptyVarsSized(varsSize(inVariables));
    outVariables := addVariables(inVariables, outVariables);
  else
    outVariables := inVariables;
  end if;
end rehashVariables;

public function traverseBackendDAEVars<ArgT>
  "Traverse all vars of a BackendDAE.Variables array."
  input BackendDAE.Variables inVariables;
  input FuncType inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output ArgT outArg;
  end FuncType;
protected
  Integer num_vars;
  array<Option<BackendDAE.Var>> vars;
algorithm
  BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(
    numberOfElements = num_vars, varOptArr = vars)) := inVariables;
  outArg := BackendDAEUtil.traverseArrayNoCopy(vars, inFunc,
    traverseBackendDAEVars2, inArg, num_vars);
end traverseBackendDAEVars;

protected function traverseBackendDAEVars2<ArgT>
  input Option<BackendDAE.Var> inVar;
  input FuncType inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output ArgT outArg;
  end FuncType;
algorithm
  outArg := match(inVar)
    local
      BackendDAE.Var v;
      ArgT arg;

    case NONE() then inArg;
    case SOME(v)
      algorithm
        (_, arg) := inFunc(v, inArg);
      then
        arg;
  end match;
end traverseBackendDAEVars2;

public function traverseBackendDAEVarsWithStop<ArgT>
  "Traverse all vars of a BackendDAE.Variables array."
  input BackendDAE.Variables inVariables;
  input FuncType inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output Boolean outContinue;
    output ArgT outArg;
  end FuncType;
protected
  Integer num_vars;
  array<Option<BackendDAE.Var>> vars;
algorithm
  BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(
    numberOfElements = num_vars, varOptArr = vars)) := inVariables;
  outArg := BackendDAEUtil.traverseArrayNoCopyWithStop(vars, inFunc,
    traverseBackendDAEVarsWithStop2, inArg, num_vars);
end traverseBackendDAEVarsWithStop;

protected function traverseBackendDAEVarsWithStop2<ArgT>
  input Option<BackendDAE.Var> inVar;
  input FuncType inFunc;
  input ArgT inArg;
  output Boolean outContinue;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output Boolean outContinue;
    output ArgT outArg;
  end FuncType;
algorithm
  (outContinue, outArg) := match(inVar)
    local
      BackendDAE.Var v;
      ArgT arg;
      Boolean cont;

    case NONE() then (true, inArg);
    case SOME(v)
      algorithm
        (_, cont, arg) := inFunc(v, inArg);
      then
        (cont, arg);
  end match;
end traverseBackendDAEVarsWithStop2;

public function traverseBackendDAEVarsWithUpdate<ArgT>
  "Traverse all vars of a BackendDAE.Variables array."
  input BackendDAE.Variables inVariables;
  input FuncType inFunc;
  input ArgT inArg;
  output BackendDAE.Variables outVariables;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output ArgT outArg;
  end FuncType;
protected
  array<list<BackendDAE.CrefIndex>> indices;
  Integer buckets, num_vars, num_elems, arr_size;
  array<Option<BackendDAE.Var>> vars;
algorithm
  BackendDAE.VARIABLES(indices, BackendDAE.VARIABLE_ARRAY(
    num_vars, arr_size, vars), buckets, num_vars) := inVariables;
  (vars, outArg) := BackendDAEUtil.traverseArrayNoCopyWithUpdate(vars, inFunc,
    traverseBackendDAEVarsWithUpdate2, inArg, num_vars);
  outVariables := BackendDAE.VARIABLES(indices,
    BackendDAE.VARIABLE_ARRAY(num_vars, arr_size, vars), buckets, num_vars);
end traverseBackendDAEVarsWithUpdate;

protected function traverseBackendDAEVarsWithUpdate2<ArgT>
  input Option<BackendDAE.Var> inVar;
  input FuncType inFunc;
  input ArgT inArg;
  output Option<BackendDAE.Var> outVar;
  output ArgT outArg;

  partial function FuncType
    input BackendDAE.Var inVar;
    input ArgT inArg;
    output BackendDAE.Var outVar;
    output ArgT outArg;
  end FuncType;
algorithm
  (outVar, outArg) := match(inVar)
    local
      Option<BackendDAE.Var> ov;
      BackendDAE.Var v, new_v;
      ArgT arg;
      Boolean cont;

    case NONE() then (inVar, inArg);

    case SOME(v)
      algorithm
        (new_v, arg) := inFunc(v, inArg);
        ov := if referenceEq(v, new_v) then inVar else SOME(new_v);
      then
        (ov, arg);

  end match;
end traverseBackendDAEVarsWithUpdate2;

public function getAllCrefFromVariables
  input BackendDAE.Variables inVariables;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := traverseBackendDAEVars(inVariables,traversingVarCrefFinder,{});
end getAllCrefFromVariables;

protected function traversingVarCrefFinder
  input BackendDAE.Var inVar;
  input list<DAE.ComponentRef> inCrefs;
  output BackendDAE.Var outVar;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (outVar,outCrefs) := matchcontinue (inVar,inCrefs)
    local
      BackendDAE.Var v;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;
    case (v,cr_lst)
      equation
        cr = varCref(v);
      then (v,cr::cr_lst);
    else (inVar,inCrefs);
  end matchcontinue;
end traversingVarCrefFinder;

public function getAllDiscreteVarFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,traversingisisVarDiscreteFinder,{});
end getAllDiscreteVarFromVariables;

protected function traversingisisVarDiscreteFinder
  input BackendDAE.Var inVar;
  input list<BackendDAE.Var> inVars;
  output BackendDAE.Var v;
  output list<BackendDAE.Var> v_lst;
algorithm
  v := inVar;
  v_lst := List.consOnTrue(BackendDAEUtil.isVarDiscrete(v),v,inVars);
end traversingisisVarDiscreteFinder;

public function getAllStateVarFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
algorithm
  v_lst := traverseBackendDAEVars(inVariables,traversingisStateVarFinder,{});
end getAllStateVarFromVariables;

protected function traversingisStateVarFinder
  input BackendDAE.Var inVar;
  input list<BackendDAE.Var> inVars;
  output BackendDAE.Var v;
  output list<BackendDAE.Var> v_lst;
algorithm
  v := inVar;
  v_lst := List.consOnTrue(isStateVar(v),v,inVars);
end traversingisStateVarFinder;

public function getAllStateDerVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
  output list<Integer> i_lst;
algorithm
  ((v_lst,i_lst,_)) := traverseBackendDAEVars(inVariables,traversingisStateDerVarIndexFinder,({},{},1));
end getAllStateDerVarIndexFromVariables;

protected function traversingisStateDerVarIndexFinder
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Var>,list<Integer>,Integer> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Var>,list<Integer>,Integer> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
      list<Integer> i_lst;
      Integer i;
    case (v,(v_lst,i_lst,i))
      equation
        true = isStateDerVar(v);
      then (v,(v::v_lst,i::i_lst,i+1));
    case (v,(v_lst,i_lst,i)) then (v,(v_lst,i_lst,i+1));
  end matchcontinue;
end traversingisStateDerVarIndexFinder;

public function getAllStateVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
  output list<Integer> i_lst;
algorithm
  ((v_lst,i_lst,_)) := traverseBackendDAEVars(inVariables,traversingisStateVarIndexFinder,({},{},1));
end getAllStateVarIndexFromVariables;

protected function traversingisStateVarIndexFinder
"author: Frenkel TUD 2010-11"
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Var>,list<Integer>,Integer> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Var>,list<Integer>,Integer> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
      list<Integer> i_lst;
      Integer i;
    case (v,(v_lst,i_lst,i))
      equation
        true = isStateVar(v);
      then (v,(v::v_lst,i::i_lst,i+1));
    case (v,(v_lst,i_lst,i)) then (v,(v_lst,i_lst,i+1));
  end matchcontinue;
end traversingisStateVarIndexFinder;

public function getAllAlgStateVarIndexFromVariables
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> v_lst;
  output list<Integer> i_lst;
algorithm
  ((v_lst,i_lst,_)) := traverseBackendDAEVars(inVariables,traversingisAlgStateVarIndexFinder,({},{},1));
end getAllAlgStateVarIndexFromVariables;

protected function traversingisAlgStateVarIndexFinder
"author: Frenkel TUD 2010-11"
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Var>,list<Integer>,Integer> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Var>,list<Integer>,Integer> outTpl;
algorithm
  (outVar,outTpl) := match (inVar,inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> v_lst;
      list<Integer> i_lst;
      Integer i;
    case (v,(v_lst,i_lst,i))
      guard isAlgState(v)
    then (v,(v::v_lst,i::i_lst,i+1));
    case (v,(v_lst,i_lst,i)) then (v,(v_lst,i_lst,i+1));
  end match;
end traversingisAlgStateVarIndexFinder;


public function mergeVariableOperations
  input BackendDAE.Var inVar;
  input list<DAE.SymbolicOperation> inOps;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef a;
  BackendDAE.VarKind b;
  DAE.VarDirection c;
  DAE.VarParallelism p;
  BackendDAE.Type d;
  Option<DAE.Exp> e;
  Option<Values.Value> f;
  list<DAE.Dimension> g;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> oattr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> s;
  DAE.ConnectorType ct;
  list<DAE.SymbolicOperation> ops;
  DAE.VarInnerOuter io;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR(varName=a,
                 varKind=b,
                 varDirection=c,
                 varParallelism=p,
                 varType=d,
                 bindExp=e,
                 bindValue=f,
                 arryDim=g,
                 source=source,
                 values=oattr,
                 tearingSelectOption=ts,
                 comment=s,
                 connectorType=ct,
                 innerOuter=io,
                 unreplaceable=unreplaceable) := inVar;
  ops := listReverse(inOps);
  source := List.foldr(ops, DAEUtil.addSymbolicTransformation, source);
  outVar := BackendDAE.VAR(a, b, c, p, d, e, f, g, source, oattr, ts, s, ct, io, unreplaceable);
end mergeVariableOperations;

public function mergeAliasVars "author: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input BackendDAE.Var inAVar "the alias var";
  input Boolean negate;
  input BackendDAE.Variables knVars "the KnownVars, needd to report Warnings";
  output BackendDAE.Var outVar;
protected
  BackendDAE.Var v,va,v1,v2;
  Boolean fixed,fixeda,f;
  Option<DAE.Exp> sv,sva,so,soa;
  DAE.Exp start;
algorithm
  // get attributes
  // fixed
  fixed := varFixed(inVar);
  fixeda := varFixed(inAVar);
  // start
  sv := varStartValueOption(inVar);
  sva := varStartValueOption(inAVar);
  so := varStartOrigin(inVar);
  soa := varStartOrigin(inAVar);
  v1 := mergeStartFixed(inVar,fixed,sv,so,inAVar,fixeda,sva,soa,negate,knVars);
  // nominal
  v2 := mergeNominalAttribute(inAVar,v1,negate);
  // minmax
  outVar := mergeMinMaxAttribute(inAVar,v2,negate);
end mergeAliasVars;

protected function mergeStartFixed
"author: Frenkel TUD 2011-04"
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input Option<DAE.Exp> sv;
  input Option<DAE.Exp> so;
  input BackendDAE.Var inAVar;
  input Boolean fixeda;
  input Option<DAE.Exp> sva;
  input Option<DAE.Exp> soa;
  input Boolean negate;
  input BackendDAE.Variables knVars "the KnownVars, needd to report Warnings";
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inVar,fixed,sv,so,inAVar,fixeda,sva,soa,negate,knVars)
    local
      BackendDAE.Var v,va,v1,v2;
      DAE.ComponentRef cr,cra;
      DAE.Exp sa,sb,e;
      Integer i,ia;
      Option<DAE.Exp> origin;
      DAE.Type ty,tya;
      Option<DAE.VariableAttributes> attr,attra;
    // legal cases one fixed the other one not fixed, use the fixed one
    case (v,true,_,_,_,false,_,_,_,_)
      then v;
    case (v,false,_,_,_,true,SOME(sb),_,_,_)
      equation
        e = if negate then Expression.negate(sb) else sb;
        v1 = setVarStartValue(v,e);
        v2 = setVarFixed(v1,true);
      then v2;
    case (v,false,NONE(),_,_,true,NONE(),_,_,_)
      equation
        v1 = setVarFixed(v,true);
      then v1;
    case (v,false,SOME(_),_,_,true,NONE(),_,_,_)
      equation
        _ = setVarStartValueOption(v,NONE());
        v1 = setVarFixed(v,true);
      then v1;
    // legal case both fixed=false
    case (v,false,NONE(),_,_,false,NONE(),_,_,_)
      then v;
    case (v,false,SOME(_),_,_,false,NONE(),_,_,_)
      then v;
    case (v,false,NONE(),_,_,false,SOME(sb),_,_,_)
      equation
        e = if negate then Expression.negate(sb) else sb;
        v1 = setVarStartValue(v,e);
      then v1;
    case (v as BackendDAE.VAR(varType=ty),false,_,_,BackendDAE.VAR(varType=tya),false,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = if negate then Expression.negate(sb) else sb;
        (e,origin) = getNonZeroStart(false,sa,so,e,soa,knVars);
        _ = setVarStartValue(v,e);
        v1 = setVarStartOrigin(v,origin);
      then v1;
    case (v as BackendDAE.VAR(varName=cr,varType=ty),false,_,_,BackendDAE.VAR(varName=cra,varType=tya),false,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = if negate then Expression.negate(sb) else sb;
        // according to MSL
        // use the value from the variable that is closer to the top of the
        // hierarchy i.e. A.B value has priority over X.Y.Z value!
        i = ComponentReference.crefDepth(cr);
        ia = ComponentReference.crefDepth(cra);
      then
        mergeStartFixed1(intLt(ia,i),v,cr,sa,cra,e,soa,negate," have start values ");
    // legal case both fixed = true and start exp equal
    case (v,true,NONE(),_,_,true,NONE(),_,_,_)
      then v;
    case (v as BackendDAE.VAR(varType=ty),true,_,_,BackendDAE.VAR(varType=tya),true,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = if negate then Expression.negate(sb) else sb;
        (e,origin) = getNonZeroStart(true,sa,so,e,soa,knVars);
        _ = setVarStartValue(v,e);
        v1 = setVarStartOrigin(v,origin);
      then v1;
    // not legal case both fixed with unequal start values
    case (v as BackendDAE.VAR(varName=cr,varType=ty),true,_,_,BackendDAE.VAR(varName=cra,varType=tya),true,_,_,_,_)
      equation
        sa = startValueType(sv,ty);
        sb = startValueType(sva,tya);
        e = if negate then Expression.negate(sb) else sb;
        // overconstrained system report warning/error
        i = ComponentReference.crefDepth(cr);
        ia = ComponentReference.crefDepth(cra);
      then
        mergeStartFixed1(intLt(ia,i),v,cr,sa,cra,e,soa,negate," both fixed and have start values ");
  end matchcontinue;
end mergeStartFixed;

protected function startValueType "author: Frenkel TUD 2012-10
  return the start value or the default value in case of NONE()"
  input Option<DAE.Exp> iExp;
  input DAE.Type iTy;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(iExp,iTy)
    local
      DAE.Exp e;
    case(SOME(e),_) then e;
    case(NONE(),_)
      equation
        true = Types.isRealOrSubTypeReal(iTy);
      then
        DAE.RCONST(0.0);
    case(NONE(),_)
      equation
        true = Types.isIntegerOrSubTypeInteger(iTy);
      then
        DAE.ICONST(0);
    case(NONE(),_)
      equation
        true = Types.isBooleanOrSubTypeBoolean(iTy);
      then
        DAE.BCONST(false);
    case(NONE(),_)
      equation
        true = Types.isStringOrSubTypeString(iTy);
      then
        DAE.SCONST("");
    else
      then
        DAE.RCONST(0.0);
  end matchcontinue;
end startValueType;

protected function mergeStartFixed1 "author: Frenkel TUD 2011-04"
  input Boolean b "true if Alias Var have less dots in the name";
  input BackendDAE.Var inVar;
  input DAE.ComponentRef cr;
  input DAE.Exp sv;
  input DAE.ComponentRef cra;
  input DAE.Exp sva;
  input Option<DAE.Exp> soa;
  input Boolean negate;
  input String s4;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  match (b,inVar,cr,sv,cra,sva,soa,negate,s4)
    local
      String s,s1,s2,s3,s5,s6;
      BackendDAE.Var v;
    // alias var has more dots in the name
    case (false,_,_,_,_,_,_,_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = if negate then " = -" else " = ";
        s3 = ComponentReference.printComponentRefStr(cra);
        s5 = ExpressionDump.printExpStr(sv);
        s6 = ExpressionDump.printExpStr(sva);
        s = stringAppendList({"Alias variables ",s1,s2,s3,s4,s5," != ",s6,". Use value from ",s1,"."});
        Error.addMessage(Error.COMPILER_WARNING,{s});
      then
        inVar;
    case (true,_,_,_,_,_,_,_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = if negate then " = -" else " = ";
        s3 = ComponentReference.printComponentRefStr(cra);
        s5 = ExpressionDump.printExpStr(sv);
        s6 = ExpressionDump.printExpStr(sva);
        s = stringAppendList({"Alias variables ",s1,s2,s3,s4,s5," != ",s6,". Use value from ",s3,"."});
        Error.addMessage(Error.COMPILER_WARNING,{s});
        v = setVarStartValue(inVar,sva);
        v = setVarStartOrigin(v,soa);
      then
        v;
  end match;
end mergeStartFixed1;

protected function replaceCrefWithBindExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean,HashSet.HashSet> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Boolean,HashSet.HashSet> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case (DAE.CREF(componentRef=cr), (vars,_,hs))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        ({BackendDAE.VAR(bindExp = SOME(e))}, _) = getVar(cr, vars);
        hs = BaseHashSet.add(cr,hs);
        (e, (_,_,hs)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (vars,false,hs));
      then (e, (vars,true,hs));
    // true if crefs in expression
    case (e as DAE.CREF(), (vars,_,hs))
      then (e, (vars,true,hs));
    else (inExp,inTuple);
  end matchcontinue;
end replaceCrefWithBindExp;

protected function getNonZeroStart
"author: Frenkel TUD 2011-04"
  input Boolean mustBeEqual;
  input DAE.Exp exp1;
  input Option<DAE.Exp> so "StartOrigin";
  input DAE.Exp exp2;
  input Option<DAE.Exp> sao "StartOrigin";
  input BackendDAE.Variables knVars "the KnownVars, need to report Warnings";
  output DAE.Exp outExp;
  output Option<DAE.Exp> outStartOrigin;
algorithm
  (outExp,outStartOrigin) :=
  matchcontinue (mustBeEqual,exp1,so,exp2,sao,knVars)
    local
      DAE.Exp exp2_1,exp1_1;
      Integer i,ia;
      Boolean b1,b2;
      Option<DAE.Exp> origin;
    case (_,_,_,_,_,_)
      equation
        true = Expression.expEqual(exp1,exp2);
        // use highest origin
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        origin = if intGt(ia,i) then sao else so;
      then (exp1,origin);
    case (false,_,_,_,_,_)
      equation
        // if one is bound and the other not use the bound one
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        false = intEq(i,ia);
        ((exp1_1,origin)) = if intGt(ia,i) then (exp2,sao) else (exp1,so);
      then
        (exp1_1,origin);
    case (_,_,_,_,_,_)
      equation
        // simple evaluation, by replace crefs with bind expressions recursivly
        (exp1_1, (_,b1,_)) = Expression.traverseExpBottomUp(exp1, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (exp2_1, (_,b2,_)) = Expression.traverseExpBottomUp(exp2, replaceCrefWithBindExp, (knVars,false,HashSet.emptyHashSet()));
        (exp1_1,_) = ExpressionSimplify.condsimplify(b1,exp1_1);
        (exp2_1,_) = ExpressionSimplify.condsimplify(b2,exp2_1);
        true = Expression.expEqual(exp1_1, exp2_1);
        exp1_1 = if b1 then exp1 else exp2;
        // use highest origin
        i = startOriginToValue(so);
        ia = startOriginToValue(sao);
        origin = if intGt(ia,i) then sao else so;
      then
        (exp1_1,origin);
  end matchcontinue;
end getNonZeroStart;

public function startOriginToValue
  input Option<DAE.Exp> startOrigin;
  output Integer i;
algorithm
  i := match(startOrigin)
    case NONE() then 0;
    case SOME(DAE.SCONST("undefined")) then 1;
    case SOME(DAE.SCONST("type")) then 2;
    case SOME(DAE.SCONST("binding")) then 3;
  end match;
end startOriginToValue;

public function mergeNominalAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      DAE.Exp e,e_1,e1,esum,eaverage;
    case (v,var,_)
      equation
        // nominal
        e = varNominalValue(v);
        e1 = varNominalValue(var);
        e_1 = if negate then Expression.negate(e) else e;
        esum = Expression.makeSum({e_1,e1});
        eaverage = Expression.expDiv(esum,DAE.RCONST(2.0)); // Real is legal because only Reals have nominal attribute
        (eaverage,_) = ExpressionSimplify.simplify(eaverage);
        var1 = setVarNominalValue(var,eaverage);
      then var1;
    case (v,var,_)
      equation
        // nominal
        e = varNominalValue(v);
        e_1 = if negate then Expression.negate(e) else e;
        var1 = setVarNominalValue(var,e_1);
      then var1;
    case(_,_,_) then inVar;
  end matchcontinue;
end mergeNominalAttribute;

protected function mergeMinMaxAttribute
  input BackendDAE.Var inAVar;
  input BackendDAE.Var inVar;
  input Boolean negate;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  matchcontinue (inAVar,inVar,negate)
    local
      BackendDAE.Var v,var,var1;
      Option<DAE.VariableAttributes> attr,attr1;
      Option<DAE.Exp> min1, min2, max1, max2;
      DAE.ComponentRef cr,cr1;

    case (v as BackendDAE.VAR(values = attr),var as BackendDAE.VAR(values = attr1),_)
      equation
        // minmax
        (min1, max1) = DAEUtil.getMinMaxValues(attr);
        (min2, max2) = DAEUtil.getMinMaxValues(attr1);
        cr = varCref(v);
        cr1 = varCref(var);
        (min1, max1) = mergeMinMax(negate, min1, min2, max1, max2, cr, cr1);
        var1 = setVarMinMax(var, min1, max1);
      then var1;

    else inVar;
  end matchcontinue;
end mergeMinMaxAttribute;

protected function mergeMinMax
  input Boolean negate;
  input Option<DAE.Exp> inMin1;
  input Option<DAE.Exp> inMin2;
  input Option<DAE.Exp> inMax1;
  input Option<DAE.Exp> inMax2;
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cr1;
  output Option<DAE.Exp> outMin;
  output Option<DAE.Exp> outMax;
algorithm
  // In case of a = -b, min and max have to be changed and negated.
  outMin := if negate then Util.applyOption(inMin1, Expression.negate) else inMin1;
  outMax := if negate then Util.applyOption(inMax1, Expression.negate) else inMax1;
  outMin := mergeMin(outMin, inMin2);
  outMax := mergeMax(outMax, inMax2);
  checkMinMax(outMin, outMax, cr, cr1, negate);
end mergeMinMax;

protected function checkMinMax
  input Option<DAE.Exp> inMin;
  input Option<DAE.Exp> inMax;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean negate;
algorithm
  _ := matchcontinue(inMin, inMax)
    local
      DAE.Exp min,max;
      String s,s1,s2,s3,s4,s5;
      Real rmin,rmax;

    case (SOME(min),SOME(max))
      equation
        rmin = Expression.toReal(min);
        rmax = Expression.toReal(max);
        true = realGt(rmin,rmax);
        s1 = ComponentReference.printComponentRefStr(cr1);
        s2 = if negate then " = -" else " = ";
        s3 = ComponentReference.printComponentRefStr(cr2);
        s4 = ExpressionDump.printExpStr(min);
        s5 = ExpressionDump.printExpStr(max);
        s = stringAppendList({"Alias variables ",s1,s2,s3," with invalid limits min ",s4," > max ",s5});
        Error.addMessage(Error.COMPILER_WARNING,{s});
      then
        ();

    // no error
    else ();
  end matchcontinue;
end checkMinMax;

protected function mergeMin
  input Option<DAE.Exp> inMin1;
  input Option<DAE.Exp> inMin2;
  output Option<DAE.Exp> outMin;
algorithm
  outMin := match(inMin1, inMin2)
    local
      DAE.Exp min1, min2, min;

    case (SOME(min1), SOME(min2))
      algorithm
        min := Expression.expMaxScalar(min1, min2);
        min := ExpressionSimplify.simplify(min);
      then
        SOME(min);

    case (NONE(), _) then inMin2;
    case (_, NONE()) then inMin1;
    else inMin1;
  end match;
end mergeMin;

protected function mergeMax
  input Option<DAE.Exp> inMax1;
  input Option<DAE.Exp> inMax2;
  output Option<DAE.Exp> outMax;
algorithm
  outMax := match(inMax1, inMax2)
    local
      DAE.Exp max1, max2, max;

    case (SOME(max1), SOME(max2))
      algorithm
        max := Expression.expMinScalar(max1, max2);
        max := ExpressionSimplify.simplify(max);
      then
        SOME(max);

    case (NONE(), _) then inMax2;
    case (_, NONE()) then inMax1;
    else inMax1;
  end match;
end mergeMax;

// protected function mergeDirection
//   input BackendDAE.Var inAVar;
//   input BackendDAE.Var inVar;
//   output BackendDAE.Var outVar;
// algorithm
//   outVar :=
//   matchcontinue (inAVar,inVar)
//     local
//       BackendDAE.Var v,var,var1;
//       Option<DAE.VariableAttributes> attr,attr1;
//       DAE.Exp e,e1;
//     case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.OUTPUT()))
//       equation
//         var1 = setVarDirection(var,DAE.INPUT());
//       then var1;
//     case (v as BackendDAE.VAR(varDirection = DAE.INPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
//       equation
//         var1 = setVarDirection(var,DAE.INPUT());
//       then var1;
//     case (v as BackendDAE.VAR(varDirection = DAE.OUTPUT()),var as BackendDAE.VAR(varDirection = DAE.BIDIR()))
//       equation
//         var1 = setVarDirection(var,DAE.OUTPUT());
//       then var1;
//     case(_,_) then inVar;
//   end matchcontinue;
// end mergeDirection;

public function calcAliasKey "author Frenkel TUD 2011-04
  helper for selectAlias. This function is
  mainly usable to chose the favorite name
  of the keeped var"
  input BackendDAE.Var var;
  output Integer i;
protected
  DAE.ComponentRef cr;
  Boolean b;
  Integer d;
algorithm
  BackendDAE.VAR(varName=cr) := var;
  // records
  b := ComponentReference.isRecord(cr);
  i := if b then -1 else 0;
  // array elements
  b := ComponentReference.isArrayElement(cr);
  i := intAdd(i,if b then -1 else 0);
  // protected
  b := isProtectedVar(var);
  i := intAdd(i,if b then 5 else 0);
  // connectors
  b := isVarConnector(var);
  i := intAdd(i,if b then 1 else 0);
  // self generated var
  b := isDummyDerVar(var);
  i := intAdd(i,if b then 10 else 0);
  b := selfGeneratedVar(cr);
  i := intAdd(i,if b then 100 else 0);
  // length of name (number of dots)
  d := ComponentReference.crefDepth(cr);
  i := i+d;
end calcAliasKey;

public function selfGeneratedVar
  input DAE.ComponentRef inCref;
  output Boolean b;
algorithm
  b := substring(ComponentReference.crefStr(inCref), 1, 1) == "$";
end selfGeneratedVar;

public function varStateSelectPrioAlias "Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Integer prio;
  protected
  DAE.StateSelect ss;
  Boolean knownDer;
algorithm
  ss := varStateSelect(v);
  prio := stateSelectToInteger(ss);
  knownDer := varHasStateDerivative(v);
  prio := prio*2;
  prio := if knownDer then prio+1 else prio;
end varStateSelectPrioAlias;

public function stateSelectToInteger "Never: -1
  Avoid: 0
  Default: 1
  Prefer: 2
  Always: 3"
  input DAE.StateSelect ss;
  output Integer prio;
algorithm
  prio := match(ss)
    case (DAE.NEVER()) then -1;
    case (DAE.AVOID()) then 0;
    case (DAE.DEFAULT()) then 1;
    case (DAE.PREFER()) then 2;
    case (DAE.ALWAYS()) then 3;
  end match;
end stateSelectToInteger;

public function transformXToXd "author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<DAE.Dimension> dim;
      Option<DAE.VariableAttributes> attr;
      Option<BackendDAE.TearingSelect> ts;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      DAE.VarInnerOuter io;
      Boolean unreplaceable;

    case (BackendDAE.VAR(varName=cr,
                         varKind=BackendDAE.STATE(),
                         varDirection=dir,
                         varParallelism=prl,
                         varType=tp,
                         bindExp=exp,
                         bindValue=v,
                         arryDim=dim,
                         source=source,
                         values=attr,
                         tearingSelectOption=ts,
                         comment=comment,
                         connectorType=ct,
                         innerOuter=io,
                         unreplaceable=unreplaceable)) equation
      cr = ComponentReference.crefPrefixDer(cr);
    then BackendDAE.VAR(cr, BackendDAE.STATE_DER(), dir, prl, tp, exp, v, dim, source, attr, ts, comment, ct, io, unreplaceable);

    else inVar;
  end matchcontinue;
end transformXToXd;

public function isRecordVar"outputs true if the variable belongs to a record.
author:Waurich TUD 2014-09"
  input BackendDAE.Var var;
  output Boolean isRec;
algorithm
  isRec := match(var)
    local
      DAE.ComponentRef cref;
    case(BackendDAE.VAR(varName=cref))
      equation
      then ComponentReference.traverseCref(cref,ComponentReference.crefIsRec, false);
  end match;
end isRecordVar;

public function varExp
  input BackendDAE.Var var;
  output DAE.Exp exp;
protected
  DAE.ComponentRef cref;
algorithm
  BackendDAE.VAR(varName=cref) := var;
  exp := Expression.crefExp(cref);
end varExp;

public function varExp2"same as varExp but adds a der()-call for state derivatives"
  input BackendDAE.Var var;
  output DAE.Exp exp;
algorithm
  exp := match(var)
  local
    DAE.ComponentRef cref;
    DAE.Exp exp1;
  case(BackendDAE.VAR(varName=cref,varKind=BackendDAE.STATE(index=1)))
    algorithm
      exp1 := Expression.crefExp(cref);
  then Expression.expDer(exp1);
  else
    algorithm
      BackendDAE.VAR(varName=cref) := var;
    then Expression.crefExp(cref);
  end match;
end varExp2;

annotation(__OpenModelica_Interface="backend");
end BackendVariable;
