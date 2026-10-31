import hashlib
import re
from dataclasses import dataclass, field

import yaml

NOTE_PREFIX = "Flashcard -> "
DECK_TAG_PREFIX = "flashcards/"

BASIC, MULTILINE, CLOZE = "basic", "multiline", "cloze"

_CLOZE = re.compile(r"==(.+?)==")
_FENCE = re.compile(r"^\s*(```|~~~)")


@dataclass(frozen=True)
class ParsedCard:
    kind: str
    front: str
    back: str
    line_number: int
    key: str


@dataclass(frozen=True)
class Problem:
    line_number: int | None
    message: str


@dataclass
class ParsedNote:
    deck_slug: str | None
    title: str
    cards: list[ParsedCard] = field(default_factory=list)
    problems: list[Problem] = field(default_factory=list)


@dataclass(frozen=True)
class _Line:
    number: int
    text: str
    code: bool


def note_title(filename: str) -> str:
    return filename.removesuffix(".md").removeprefix(NOTE_PREFIX)


def card_key(deck_slug: str, title: str, question: str) -> str:
    normalized = " ".join(question.split())
    return hashlib.sha256("\n".join((title, normalized)).encode()).hexdigest()


def parse_note(text: str, filename: str) -> ParsedNote:
    lines = text.splitlines()
    deck_slug, body_start, problem = _read_deck(lines)
    note = ParsedNote(deck_slug, note_title(filename))
    if problem:
        note.problems.append(problem)
        return note
    builder = _Builder(note)
    for block in _blocks(lines, body_start):
        _parse_block(block, builder)
    return note


def _read_deck(lines: list[str]) -> tuple[str | None, int, Problem | None]:
    if not lines or lines[0].strip() != "---":
        return None, 0, Problem(None, f"nota senza frontmatter con il tag {DECK_TAG_PREFIX}<mazzo>: saltata")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        return None, 0, Problem(None, "frontmatter non chiuso: nota saltata")
    try:
        data = yaml.safe_load("\n".join(lines[1:end])) or {}
    except yaml.YAMLError:
        return None, 0, Problem(None, "frontmatter malformato: nota saltata")

    tags = data.get("tags") if isinstance(data, dict) else None
    if isinstance(tags, str):
        tags = tags.replace(",", " ").split()
    for tag in tags or []:
        tag = str(tag).lstrip("#")
        if tag.startswith(DECK_TAG_PREFIX) and len(tag) > len(DECK_TAG_PREFIX):
            slug = tag.removeprefix(DECK_TAG_PREFIX)
            parts = slug.split("/")
            if len(parts) > 2 or any(not part for part in parts):
                return None, 0, Problem(
                    None,
                    f"tag {tag} non valido: usa {DECK_TAG_PREFIX}<mazzo>[/<sottomazzo>]",
                )
            return slug, end + 1, None
    return None, 0, Problem(None, f"nota senza tag {DECK_TAG_PREFIX}<mazzo>: saltata")


def _blocks(lines: list[str], start: int) -> list[list[_Line]]:
    blocks: list[list[_Line]] = [[]]
    in_fence = False
    for index in range(start, len(lines)):
        text = lines[index]
        is_fence = bool(_FENCE.match(text))
        if not in_fence and not is_fence and not text.strip():
            blocks.append([])
            continue
        blocks[-1].append(_Line(index + 1, text.rstrip(), code=in_fence or is_fence))
        if is_fence:
            in_fence = not in_fence
    return [block for block in blocks if block]


def _parse_block(block: list[_Line], builder: "_Builder") -> None:
    pending: list[_Line] = []
    for index, line in enumerate(block):
        stripped = line.text.strip()
        if line.code or stripped.startswith("|"):
            pending.append(line)
        elif stripped == "?":
            builder.multiline(pending, block[index + 1 :], line.number)
            return
        elif stripped == "??":
            builder.problem(line.number, "formato inverso '??' non supportato")
            return
        elif stripped.startswith("#"):
            pending = []
        elif parts := _split_basic(stripped):
            builder.basic(*parts, line.number)
            pending = []
        elif _CLOZE.search(stripped):
            builder.cloze(stripped, line.number)
            pending = []
        else:
            pending.append(line)


def _split_basic(text: str) -> tuple[str, str] | None:
    in_code = False
    for i, char in enumerate(text):
        if char == "`":
            in_code = not in_code
        elif not in_code and text.startswith("::", i):
            separator = 3 if text.startswith(":::", i) else 2
            return text[:i].strip(), text[i + separator :].strip()
    return None


def _render_cloze(text: str, gaps: list[re.Match], target: int, template: str) -> str:
    parts, last = [], 0
    for index, gap in enumerate(gaps):
        parts.append(text[last : gap.start()])
        parts.append(template.format(gap.group(1)) if index == target else gap.group(1))
        last = gap.end()
    parts.append(text[last:])
    return "".join(parts)


class _Builder:

    def __init__(self, note: ParsedNote):
        self.note = note
        self.keys: set[str] = set()

    def problem(self, line_number: int, message: str) -> None:
        self.note.problems.append(Problem(line_number, message))

    def basic(self, question: str, answer: str, line_number: int) -> None:
        if not question or not answer:
            self.problem(line_number, "card '::' con domanda o risposta vuota")
            return
        self._add(BASIC, question, question, answer, line_number)

    def multiline(self, question: list[_Line], answer: list[_Line], qmark_line: int) -> None:
        if not question:
            self.problem(qmark_line, "'?' senza una domanda prima")
            return
        if not answer:
            self.problem(qmark_line, "'?' senza una risposta dopo")
            return
        front = "\n".join(line.text for line in question)
        back = "\n".join(line.text for line in answer)
        self._add(MULTILINE, front, front, back, question[0].number)

    def cloze(self, text: str, line_number: int) -> None:
        gaps = list(_CLOZE.finditer(text))
        for index in range(len(gaps)):
            front = _render_cloze(text, gaps, index, "[...]")
            back = _render_cloze(text, gaps, index, "**{}**")
            self._add(CLOZE, f"{text} [{index}]", front, back, line_number)

    def _add(self, kind: str, question: str, front: str, back: str, line_number: int) -> None:
        key = card_key(self.note.deck_slug, self.note.title, question)
        if key in self.keys:
            self.problem(line_number, "domanda duplicata nella nota: tenuta la prima")
            return
        self.keys.add(key)
        self.note.cards.append(ParsedCard(kind, front, back, line_number, key))
