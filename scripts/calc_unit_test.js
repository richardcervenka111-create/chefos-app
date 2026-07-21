#!/usr/bin/env node
/*
 * Sautero calculation unit tests (Richard, 21.7.2026 — P1: "behaviorálne money-paths + calc unit testy").
 *
 * WHAT THIS IS: fast, pure, deterministic unit tests for the money-critical calculation
 * functions inside the single-file app — the ones where a wrong NUMBER costs real money:
 *   - computeRecipeCost   : menu costing (yield-adjusted effective price -> a bug here
 *                           misprices every dish on the menu)
 *   - parseQtyUnit / convertToBaseUnit : the unit parsing + conversion the cost math is built on
 *   - workingTimeHoursForEntry / computeWorkingTimeSummary : PAYROLL hours (break deduction,
 *                           daily >8h overtime) -> a bug here mis-pays staff
 *   - shiftCodeHours      : schedule hours (segment + break-note deduction, overnight wrap)
 *   - formatHoursSK       : the hours the user actually reads
 *   - normalizeIngredientText : the ingredient-name match key the cost lookup depends on
 *
 * WHY IT'S DIFFERENT from the smoke / gates tests: those check "does the screen open / not
 * crash". This checks "is the ANSWER correct" — the class of bug that opens a screen fine and
 * shows a wrong price. Those are invisible to a does-it-open test and are exactly the ones
 * that cost money.
 *
 * HOW IT RUNS in a buildless single-file project with no test framework: it reads
 * app/index.html, extracts each named function's source with a proper JS scanner (skips
 * strings / template literals / regex literals / comments, so a regex like /\d{1,2}/ inside
 * shiftCodeHours doesn't fool the brace matcher), evaluates just those functions in an
 * isolated scope with the two globals they read (_ingredientLookup, _monthTimeEntries) made
 * settable per-test, and asserts. No DOM, no network, no Supabase — pure functions only.
 *
 * The expected values were captured from the REAL functions running live on app.sautero.ch
 * (21.7.), so this encodes actual current behaviour; if a future edit changes an answer, the
 * test goes red. Runs on every push (health-checks.yml + deploy gate) — a calc regression
 * blocks deployment, same tier as the auditors.
 *
 * Node only (CI has it; there is no local JS engine). Exit 0 = all pass, 1 = a calc broke.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const SRC = fs.readFileSync(path.join(__dirname, '..', 'app', 'index.html'), 'utf8');

/* Extract `function NAME(...) { ... }` source from the app, brace-matching with a scanner that
 * ignores braces inside strings, template literals, regex literals, and comments. The regex-vs-
 * division call is the standard heuristic: a '/' begins a regex when the previous significant
 * token is an operator/keyword context (e.g. after '(', ',', '=', 'return', '['), else it's a
 * divide. Good enough for real code and specifically for the '/'-heavy money functions here. */
function extractFn(name) {
  const sig = 'function ' + name + '(';
  const start = SRC.indexOf(sig);
  if (start < 0) throw new Error('calc_unit_test: function not found in app/index.html: ' + name);
  let i = SRC.indexOf('{', SRC.indexOf(')', start));
  let depth = 0, prevSig = '';
  const REGEX_OK_BEFORE = new Set(['(', ',', '=', ':', '[', '!', '&', '|', '?', '{', '}', ';', '+', '-', '*', '%', '<', '>', '~', '^']);
  for (let j = i; j < SRC.length; j++) {
    const c = SRC[j], n = SRC[j + 1];
    // comments
    if (c === '/' && n === '/') { j = SRC.indexOf('\n', j); if (j < 0) j = SRC.length; continue; }
    if (c === '/' && n === '*') { j = SRC.indexOf('*/', j + 2) + 1; continue; }
    // strings / template literals
    if (c === '"' || c === "'" || c === '`') {
      const q = c;
      for (j++; j < SRC.length; j++) { if (SRC[j] === '\\') { j++; continue; } if (SRC[j] === q) break; }
      prevSig = q; continue;
    }
    // regex literal (only in a value position)
    if (c === '/' && REGEX_OK_BEFORE.has(prevSig)) {
      for (j++; j < SRC.length; j++) {
        if (SRC[j] === '\\') { j++; continue; }
        if (SRC[j] === '[') { for (j++; j < SRC.length && SRC[j] !== ']'; j++) { if (SRC[j] === '\\') j++; } continue; }
        if (SRC[j] === '/') break;
      }
      prevSig = '/'; continue;
    }
    if (c === '{') depth++;
    else if (c === '}') { depth--; if (depth === 0) return SRC.slice(start, j + 1); }
    if (!/\s/.test(c)) prevSig = c;
  }
  throw new Error('calc_unit_test: unbalanced braces extracting ' + name);
}

// Build one scope holding the extracted functions + the two globals they read, settable per test.
const FUNCS = ['normalizeIngredientText', 'parseQtyUnit', 'convertToBaseUnit', 'computeRecipeCost',
               'formatHoursSK', 'workingTimeHoursForEntry', 'computeWorkingTimeSummary', 'shiftCodeHours'];
const body =
  'let _ingredientLookup = {}, _monthTimeEntries = [];\n' +
  FUNCS.map(extractFn).join('\n\n') + '\n' +
  'return { ' + FUNCS.join(', ') +
  ', setLookup: o => { _ingredientLookup = o; }, setEntries: a => { _monthTimeEntries = a; } };';
const M = new Function(body)();

// ---- tiny assert harness ----
let pass = 0, fail = 0;
const near = (a, b) => Math.abs(a - b) < 1e-9;
function eq(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g === w || (typeof got === 'number' && typeof want === 'number' && near(got, want))) { pass++; }
  else { fail++; console.log(`  [FAIL] ${name}\n         got  ${g}\n         want ${w}`); }
}

// ---- parseQtyUnit ----
eq('parseQtyUnit 500 g', M.parseQtyUnit('500 g'), { amount: 500, unit: 'g' });
eq('parseQtyUnit 1,5 kg (comma decimal)', M.parseQtyUnit('1,5 kg'), { amount: 1.5, unit: 'kg' });
eq('parseQtyUnit 2 cloves -> pc', M.parseQtyUnit('2 cloves'), { amount: 2, unit: 'pc' });
eq('parseQtyUnit 1/2 l (fraction)', M.parseQtyUnit('1/2 l'), { amount: 0.5, unit: 'l' });
eq('parseQtyUnit bare number -> pc', M.parseQtyUnit('3'), { amount: 3, unit: 'pc' });
eq('parseQtyUnit "to taste" -> null', M.parseQtyUnit('to taste'), null);
eq('parseQtyUnit range "2-3 pcs" -> null', M.parseQtyUnit('2-3 pcs'), null);

// ---- convertToBaseUnit ----
eq('convert 500 g -> kg', M.convertToBaseUnit(500, 'g', 'kg'), 0.5);
eq('convert 250 ml -> l', M.convertToBaseUnit(250, 'ml', 'l'), 0.25);
eq('convert 2 kg -> kg (same)', M.convertToBaseUnit(2, 'kg', 'kg'), 2);
eq('convert g -> pc incompatible -> null', M.convertToBaseUnit(500, 'g', 'pc'), null);

// ---- normalizeIngredientText ----
eq('normalize plural', M.normalizeIngredientText('Tomatoes'), 'tomato');
eq('normalize paren+comma', M.normalizeIngredientText('Cherry Tomatoes (ripe), diced'), 'cherry tomato');
eq('normalize -oes', M.normalizeIngredientText('Potatoes'), 'potato');

// ---- computeRecipeCost (THE money function): yield-adjusted + honest matched/total ----
M.setLookup({
  'tomato': { price: 2.0, unit: 'kg', yield_pct: 100 },
  'beef':   { price: 20.0, unit: 'kg', yield_pct: 80 }, // effective 25/kg
});
const cost = M.computeRecipeCost({ sections: [{ type: 'table', rows: [
  ['Tomatoes', '500 g'],  // 0.5kg * 2.00 = 1.00
  ['Beef', '200 g'],      // 0.2kg * 25.00 = 5.00 (yield 80%)
  ['Water', 'to taste'],  // unmatched (no parseable qty)
  ['Unicorn', '100 g'],   // unmatched (not in lookup)
] }] });
eq('recipe cost sum (yield-adjusted)', cost.costSum, 6.0);
eq('recipe cost matched lines', cost.matched, 2);
eq('recipe cost total lines', cost.total, 4);
eq('recipe cost beef effective unit price (yield 80%)', cost.lines[1].unitPrice, 25);
// zero-coverage recipe stays honest, not a fake 0-cost
M.setLookup({});
const cost0 = M.computeRecipeCost({ sections: [{ type: 'table', rows: [['Anything', '100 g']] }] });
eq('recipe cost no matches -> matched 0 of 1', [cost0.matched, cost0.total], [0, 1]);

// ---- workingTimeHoursForEntry (payroll) ----
eq('WT 08:00-16:30 minus 30min break = 8.0', M.workingTimeHoursForEntry(
  { check_in: '2026-07-21T08:00:00Z', check_out: '2026-07-21T16:30:00Z', break_minutes: 30 }), 8);
eq('WT 09:00-12:00 no break = 3.0', M.workingTimeHoursForEntry(
  { check_in: '2026-07-21T09:00:00Z', check_out: '2026-07-21T12:00:00Z' }), 3);
eq('WT break longer than shift clamps at 0', M.workingTimeHoursForEntry(
  { check_in: '2026-07-21T09:00:00Z', check_out: '2026-07-21T09:10:00Z', break_minutes: 30 }), 0);

// ---- computeWorkingTimeSummary: daily >8h overtime, day grouping ----
M.setEntries([
  { check_in: '2026-07-20T08:00:00Z', check_out: '2026-07-20T18:00:00Z' }, // 10h -> 2h OT
  { check_in: '2026-07-21T08:00:00Z', check_out: '2026-07-21T14:00:00Z' }, // 6h  -> 0 OT
]);
const sum = M.computeWorkingTimeSummary();
eq('WT summary daysWorked', sum.daysWorked, 2);
eq('WT summary totalHours', sum.totalHours, 16);
eq('WT summary overtime (only the 10h day, >8)', sum.overtimeHours, 2);

// ---- formatHoursSK (comma decimal, 1dp) ----
eq('formatHoursSK 8', M.formatHoursSK(8), '8,0');
eq('formatHoursSK 7.75 -> 7,8', M.formatHoursSK(7.75), '7,8');
eq('formatHoursSK 0.05 -> 0,1', M.formatHoursSK(0.05), '0,1');

// ---- shiftCodeHours (the regex-with-braces function) ----
eq('shift 09:00-17:00 = 8', M.shiftCodeHours({ start_time: '09:00', end_time: '17:00' }), 8);
eq('shift with break-note 12:00-12:30 deducted = 8', M.shiftCodeHours(
  { start_time: '09:00', end_time: '17:30', break_note: '12:00-12:30' }), 8);
eq('shift absence = 0', M.shiftCodeHours({ is_absence: true, start_time: '09:00', end_time: '17:00' }), 0);
eq('shift overnight 22:00-06:00 wraps = 8', M.shiftCodeHours({ start_time: '22:00', end_time: '06:00' }), 8);

// ---- report ----
console.log(`\ncalc_unit_test: ${pass} passed, ${fail} failed`);
if (fail === 0) console.log('calc_unit_test: clean — all money-path calculations match their verified golden values.');
process.exit(fail === 0 ? 0 : 1);
