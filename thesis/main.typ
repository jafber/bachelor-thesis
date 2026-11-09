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
  translation: "Folgt der Rechenschritt aus der Frage? Erkennung von Denkfehlern durch kontextuelle Kalibrierung",
  signature: image("figures/signature.png", width: 4cm),
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
  labels: (
    declaration-text: [
      I hereby declare that I wrote this thesis independently and used only the sources and aids disclosed in this thesis, including the generative AI use described below. Material taken from other sources, whether quoted or paraphrased, is acknowledged. I have reviewed the work produced with AI assistance and take responsibility for the content, methods, results, and conclusions of this thesis.
    ],
  ),
)

#abstract[
  #include "abstract.typ"
]

#abstract-de[
  #include "abstract-de.typ"
]

// #acknowledgements[
//   Thanks to ...
// ]

#acronyms[
  #print-glossary(abbreviations, disable-back-references: true)
]

#ai-declaration[
  I used GPT-6 through the pi coding-agent harness for the following tasks:

  - Writing code to run the experiments and generate the plots.
  - Reformatting the illustrations @intro-figure and @experiment-overview; I created their original layouts by hand in Draw.io.
  - Producing drafts of the background, methods, and results sections.
  - Proofreading and improving the wording throughout the thesis.
  - Translating the abstract into German.
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
