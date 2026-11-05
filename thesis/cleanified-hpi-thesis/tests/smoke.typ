#import "../template/lib.typ": abstract, abstract-de, acknowledgements, project
#import "../template/lib.typ": acronyms, ai-declaration, appendix

#let variant = sys.inputs.at("variant", default: "screen")
#let full = variant != "minimal"

#show: project.with(
  title: "Template Smoke Test",
  translation: if full { "Vorlagentest" } else { "" },
  name: "Max Mustermann",
  date: "6 August 2026",
  type: "Master",
  lang: sys.inputs.at("lang", default: "en"),
  study-program: "IT-Systems Engineering",
  chair: "Data-Intensive Internet Computing",
  professors: if full { ("Professor One", "Professor Two") } else {
    ("Professor One",)
  },
  advisors: if full { ("Advisor One", "Advisor Two") } else {
    ("Advisor One",)
  },
  layout: (for-print: variant == "print"),
  labels: (
    examiner: "Examiner",
    examiners: "Examiners",
    advisor: "Advisor",
    advisors: "Advisors",
  ),
)

#if full [
  #acknowledgements[Third front section.]
  #abstract-de[Second front section.]
  #abstract[First front section with an abstract-only citation @abstract-only.]
  #abstract[Second abstract marker.]
  #acronyms[API -- Application Programming Interface]
]

= Introduction <chapter>

This is a reference to @chapter and a body citation @body-source.
#if full [The supplemental material is in @appendix-a.]

#lorem(500)

#figure(
  table(
    columns: 2,
    table.header([Name], [Value]),
    [Alpha], [1],
    [Beta], [2],
  ),
  caption: [Smoke table],
)

#if full [
  #appendix[
    == Supplemental Material <appendix-a>

    This appendix has an appendix-only citation @appendix-only.
  ]
]

#bibliography("references.bib", style: "ieee")

#if full [
  #ai-declaration[First disclosure.]
  #ai-declaration[Second disclosure.]
]
