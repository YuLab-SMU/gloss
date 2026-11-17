# M4 real-model smoke

A local OpenAI-compatible gateway ran the `meaning` stage on the fixed mtcars
point fixture. The task supplied an existing element anchor and required an
immediate `propose` call. The model made four proposals, one committed and
three rejected by the checked proposal boundary. The run used 5,594 tokens and
had one gateway retry. No key or raw prompt was archived.
