= Results and Discussion

== Does low context relevance correlate with reasoning errors?

- clear correlation accross all models and benchmarks
- lowest AUROC: .648 (qwen3.5-4b on mr-gsm8k), highest .688 (9b on big-bench-mistake)

#figure(
  image("fully-ablated-cr-comparison.png"),
  caption: [@auroc of fully ablated context relevance scores for classifying first error steps. $0.5$ means low context relevance does not correlate to first errors; $1.0$ means perfect correlation. P-values are calculated by Mann Whitney U test; they denote the likelihood that, on average, first error steps do _not_ have lower context relevance than other reasoning steps.]
)

== How accurately can current @llm:pl detect reasoning errors?

#figure(
  image("tyen.png"),
  caption: [@auroc of fully ablated context relevance scores for classifying first error steps. $0.5$ means low context relevance does not correlate to first errors; $1.0$ means perfect correlation. P-values are calculated by Mann Whitney U test; they denote the likelihood that, on average, first error steps do _not_ have lower context relevance than other reasoning steps.]
)

== How does @dcpmi compare to @llm critics?

== Performance in tracking shuffled objects task
