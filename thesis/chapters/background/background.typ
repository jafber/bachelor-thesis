= Background

== Generation process of @llm:pl

== @llm Reasoning

== Existing @cot:long monitoring approaches

=== Process Reward Models

=== @llm critics

== Applying information theory to @cot:long

=== Perplexity

=== @dcpmi


= Our new metric: context relevance <cr>

$ op("CR")_"generic" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g) $

$ op("CR")_"history-ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q) $

$ op("CR")_"question-ablated" (i) = L(s_i | q, s_(<i)) - L(s_i | q_g, s_(<i)) $
