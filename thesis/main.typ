// For local development, replace the import below with:
// #import "../template/lib.typ": *
#import "./cleanified-hpi-thesis/template/lib.typ": *
#import "@preview/glossarium:0.5.10": *
#show: make-glossary

#let abbreviations = (
  (
    key: "cot",
    short: "CoT",
    long: "Chain of Thought",
  ),
  (
    key: "prm",
    short: "PRM",
    long: "Process Reward Model",
    longplural: "Process Reward Models",
  ),
  (
    key: "llm",
    short: "LLM",
    long: "Large Language Model",
  ),
  (
    key: "pmi",
    short: "PMI",
    long: "Pointwise Mutual Information",
  ),
  (
    key: "dcpmi",
    short: "DC-PMI",
    long: "Domain Conditional Pointwise Mutual Information",
  ),
  (
    key: "nli",
    short: "NLI",
    long: "Natural Language Inference",
  ),
  (
    key: "mcc",
    short: "MCC",
    long: "Matthews Correlation Coefficient",
  ),
  (
    key: "auroc",
    short: "AUROC",
    long: "Area Under Receiver Operating Curve",
  ),
)

#register-glossary(abbreviations)

#show: project.with(
  title: "Does the Question Support This Reasoning Step?",
  subtitle: "Detecting Reasoning Errors with Contextual Calibration",
  name: "Jan Berndt",
  date: "9. November 2026",
  study-program: "IT-Systems Engineering",
  chair: "Artificial Intelligence and Intelligent Systems",
  professors: ("Prof. Dr. Gerard de Melo",),
  advisors: ("Yindong Wang",),
  type: "Bachelor",
  lang: "en",  // Switch all labels to German defaults
  // typography: (font: "STIX Two Text", body-text-size: 12pt),
  // layout: (for-print: true, toc-depth: 2),
  // appearance: (accent-color: rgb("#B1063A")),
  // labels: (declaration-city: "Berlin"),
)

#abstract[
  #include "abstract.typ"
]

// #abstract-de[
//   Dies ist eine wirklich gute Zusammenfassung.
// ]

// #acknowledgements[
//   Thanks to ...
// ]

#acronyms[
  #print-glossary(abbreviations, disable-back-references: true)
]

#ai-declaration[
  Describe any use of generative AI tools here.
]

#include "chapters/intro.typ"
#include "chapters/background.typ"
#include "chapters/methods.typ"
#include "chapters/results.typ"
#include "chapters/conclusion.typ"

#bibliography("zotero.bib", style: "apa")

#appendix[
  #include "appendix.typ"
]
