import sys

def b(val, width):
    if val < 0:
        val = (1 << width) + val
    s = format(val & ((1<<width)-1), '0{}b'.format(width))
    return s

def R(rname):
    return int(rname[1:])

def rfmt(op11, rm, rn, rd, shamt=0):
    return op11 + b(rm,5) + b(shamt,6) + b(rn,5) + b(rd,5)

def ifmt(op10, imm12, rn, rd):
    return op10 + b(imm12,12) + b(rn,5) + b(rd,5)

def dfmt(op11, imm9, rn, rt):
    return op11 + b(imm9,9) + '00' + b(rn,5) + b(rt,5)

def bfmt(op6, imm26):
    return op6 + b(imm26,26)

def cbfmt(op8, imm19, rt_or_cond):
    return op8 + b(imm19,19) + b(rt_or_cond,5)

OP = {
 'ADDS': '10101011000', 'SUBS': '11101011000', 'BR': '11010110000',
 'ADDI': '1001000100',
 'STUR': '11111000000', 'LDUR': '11111000010',
 'B': '000101', 'BL': '100101',
 'CBZ': '10110100', 'BCOND': '01010100',
}
COND_LT = 0b01011

lines = []
labels = {}

# ---- program (index, label optional) ----
prog = [
 (None, 'ADDI', 'X1','X31',5),
 (None, 'ADDI', 'X2','X31',10),
 (None, 'ADDS', 'X3','X1','X2'),
 (None, 'SUBS', 'X4','X1','X2'),
 (None, 'STUR', 'X3','X31',0),
 (None, 'LDUR', 'X5','X31',0),
 (None, 'CBZ',  'X31','SKIP'),
 (None, 'ADDI', 'X6','X31',99),
 ('SKIP', 'ADDI', 'X7','X31',7),
 (None, 'BLT',  'ELSE'),
 (None, 'ADDI', 'X8','X31',111),
 ('ELSE', 'ADDI', 'X9','X31',42),
 (None, 'BL',   'SUB1'),
 (None, 'ADDI', 'X10','X31',55),
 (None, 'B',    'END'),
 ('SUB1','ADDI', 'X11','X31',77),
 (None, 'BR',   'X30'),
 ('END', 'ADDI', 'X12','X31',1),
 ('HALT', 'B', 'HALT'),
]

# pass 1: assign addresses / labels
for idx, entry in enumerate(prog):
    label = entry[0]
    if label:
        labels[label] = idx

# pass 2: encode
out = []
for idx, entry in enumerate(prog):
    _, op = entry[0], entry[1]
    args = entry[2:]
    if op == 'ADDI':
        rd, rn, imm = args
        out.append(ifmt(OP['ADDI'], imm, R(rn), R(rd)))
    elif op in ('ADDS','SUBS'):
        rd, rn, rm = args
        out.append(rfmt(OP[op], R(rm), R(rn), R(rd)))
    elif op == 'STUR':
        rt, rn, imm = args
        out.append(dfmt(OP['STUR'], imm, R(rn), R(rt)))
    elif op == 'LDUR':
        rt, rn, imm = args
        out.append(dfmt(OP['LDUR'], imm, R(rn), R(rt)))
    elif op == 'CBZ':
        rt, label = args
        off = labels[label] - idx
        out.append(cbfmt(OP['CBZ'], off, R(rt)))
    elif op == 'BLT':
        (label,) = args
        off = labels[label] - idx
        out.append(cbfmt(OP['BCOND'], off, COND_LT))
    elif op == 'B':
        (label,) = args
        off = labels[label] - idx
        out.append(bfmt(OP['B'], off))
    elif op == 'BL':
        (label,) = args
        off = labels[label] - idx
        out.append(bfmt(OP['BL'], off))
    elif op == 'BR':
        (rn,) = args
        out.append(rfmt(OP['BR'], 0, R(rn), 0))
    else:
        raise ValueError(op)

for i, line in enumerate(out):
    assert len(line) == 32, (i, line, len(line))
    print(line)
