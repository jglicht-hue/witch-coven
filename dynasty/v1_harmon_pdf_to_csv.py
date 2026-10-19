#!/usr/bin/env python3
"""v1_harmon_pdf_to_csv.py
Turns a PDF print of Reception Perception's "Matt Harmon's Dynasty WR Rankings"
tool into a CSV with one row per receiver.

Usage: python3 v1_harmon_pdf_to_csv.py <input.pdf> <output.csv>
Needs: pip install pdfplumber

The PDF is a web page printed at very small type, so plain text extraction
mixes the columns together. This script reads each character's position and
font size instead. It stops with an error if its own checks fail.
"""
import sys, re, csv, collections, logging
import pdfplumber

logging.getLogger("pdfminer").setLevel(logging.ERROR)

NAME_SIZE, NOTE_SIZE = 4.05, 3.15      # font sizes in the Oct 3, 2026 print
NAME_X = (185, 330)                    # left edge of the player column
NOTE_X = 362                           # left edge of the note column
ROW_ABOVE, ROW_BELOW = 3, 10           # a row's band around its name line


def line_text(chars):
    """Join characters into text, top to bottom, left to right."""
    lines = collections.defaultdict(list)
    for c in chars:
        lines[round(c["top"], 1)].append(c)
    parts = []
    for top in sorted(lines):
        parts.append("".join(c["text"] for c in sorted(lines[top], key=lambda c: c["x0"])).strip())
    return " ".join(p for p in parts if p)


def parse(pdf_path):
    rows = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            chars = page.chars
            names = collections.defaultdict(list)
            for c in chars:
                if abs(c["size"] - NAME_SIZE) < 0.05 and NAME_X[0] <= c["x0"] <= NAME_X[1]:
                    names[round(c["top"], 1)].append(c)
            for top in sorted(names):
                name = "".join(c["text"] for c in sorted(names[top], key=lambda c: c["x0"])).strip()
                band = [c for c in chars if top - ROW_ABOVE <= c["top"] < top + ROW_BELOW]
                left = [c for c in band if c["x0"] < NOTE_X and abs(c["size"] - NAME_SIZE) >= 0.05]
                note = line_text([c for c in band if c["x0"] >= NOTE_X and abs(c["size"] - NOTE_SIZE) < 0.05])
                rows.append((name, left, note.replace("", "").strip()))
    return rows


def fields(name, left, note):
    # Each field is found by its pattern inside its own slice of the row,
    # so stray menu text printed over the table can't leak in.
    def seg(x0, x1, lo=0.0, hi=99.0):
        return line_text([c for c in left if x0 <= c["x0"] < x1 and lo <= c["size"] < hi])
    name = re.sub(r"[\ue000-\uf8ff]", "", name).strip()
    rank_m = re.search(r"\b(\d{1,3})\b", seg(150, 172, lo=3.4))
    # The arrow and its number sit on slightly different lines, so read them apart.
    mv = sorted((c for c in left if 160 <= c["x0"] < 185 and c["size"] < 3.0), key=lambda c: c["x0"])
    arrow = next((c["text"] for c in mv if c["text"] in "▲▼"), "")
    digits = "".join(c["text"] for c in mv if c["text"].isdigit())
    move = (("+" if arrow == "▲" else "-") + digits) if arrow and digits else ""
    team_txt = seg(185, 250, hi=3.0)
    team = age = year = ""
    m = re.search(r"\b([A-Z]{2,3})\s*·\s*(\d\d\.\d)\s*YRS", team_txt)
    if m:
        team, age = m.group(1), m.group(2)
    else:
        m = re.search(r"\b([A-Z]{2,3})\s*·\s*'\d\d", team_txt)   # no age shown
        if m:
            team = m.group(1)
        else:
            # A row cut by the page edge loses its dots: "GB264YRS'23DRAFT".
            m = re.search(r"([A-Z]{2,3})·?(\d\d)\.?(\d)YRS", re.sub(r"\s+", "", team_txt))
            if m:
                team, age = m.group(1), m.group(2) + "." + m.group(3)
    y = re.search(r"'(\d\d)", team_txt)
    year = ("20" + y.group(1)) if y else ""
    call_txt = seg(250, 279, hi=3.0) + " " + seg(160, 250, hi=2.3)
    call = "SUPER BUY" if "SUPER" in call_txt else next((c for c in ("BUY", "HOLD", "SELL") if c in call_txt), "")
    sig_txt = seg(279, 319, hi=3.0)
    if "Sell" in sig_txt: signal = "Strong Sell Window"
    elif "RP" in sig_txt and "Buy" in sig_txt: signal = "Strong RP Buy"
    elif "Discount" in sig_txt: signal = "Market Discount"
    elif "Premium" in sig_txt: signal = "Market Premium"
    elif "Aligned" in sig_txt: signal = "Market Aligned"
    else: signal = ""
    mkt_m = re.search(r"#(\d+(?:\.\d)?)", seg(319, 341))
    gap_txt = seg(279, NOTE_X)
    gap_m = re.search(r"([+-])\s?(\d+(?:\.\d)?)", gap_txt)
    gap = "0" if "EVEN" in gap_txt else (gap_m.group(1) + gap_m.group(2) if gap_m else "")
    return [
        int(rank_m.group(1)) if rank_m else None,
        name, team, age, year,
        move,
        call, signal,
        mkt_m.group(1) if mkt_m else "",
        gap, note,
    ]


def main(pdf_path, csv_path):
    out = [fields(*r) for r in parse(pdf_path)]
    # Lines in the name font that aren't table rows (page headings) have no rank.
    out = [o for o in out if o[0] is not None]
    # Self-checks. Any failure means the print layout differs from Oct 3, 2026.
    problems = []
    ranks = [o[0] for o in out]
    if ranks != list(range(1, len(out) + 1)):
        problems.append("ranks are not 1..N in order: %s" % ranks[:12])
    for o in out:
        if not o[6]:
            problems.append("no call for rank %s %s" % (o[0], o[1]))
        if not o[2]:
            problems.append("no team for rank %s %s" % (o[0], o[1]))
        if o[8] and o[9] and o[0] and abs((float(o[8]) - o[0]) - float(o[9])) > 0.11:
            problems.append("gap is not market minus rank for rank %s %s" % (o[0], o[1]))
    if problems:
        sys.exit("STOP, the checks failed:\n  " + "\n  ".join(problems[:20]))
    with open(csv_path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["RP Rank", "Player", "Team", "Age", "Draft Year", "Rank Move", "RP Call", "Signal",
                    "Market Avg WR Rank", "Gap (Market minus RP)", "Note (as shown; cut off where it ends in …)"])
        w.writerows(out)
    print("%d receivers written to %s" % (len(out), csv_path))
    print("no market number:", ", ".join(o[1] for o in out if not o[8]) or "none")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
