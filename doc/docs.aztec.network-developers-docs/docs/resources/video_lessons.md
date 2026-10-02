# Video lessons

> Source: https://docs.aztec.network/developers/docs/resources/video_lessons

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Resources
- Video lessons

On this page
# Video lessons

Prefer watching to reading? These short explainers, presented by Ciara Nightingale from the Aztec team, each cover a core Aztec concept in just a few minutes. Written pages that go deeper are linked below each video.

## What is Aztec?[​](#what-is-aztec)

Aztec is a privacy-first Layer 2 on Ethereum: a zero-knowledge rollup where smart contracts can have both public and private state, and private execution happens locally on your own device. This video explains the core idea in under 90 seconds.

Related reading: [Aztec overview](https://docs.aztec.network/developers/overview), [foundational topics](https://docs.aztec.network/developers/docs/foundational-topics)

## Private and public state in one transaction[​](#private-and-public-state-in-one-transaction)

A single Aztec transaction can span private and public execution. Using a private voting contract as the example, this video shows how private execution runs first on your device, producing a proof and side effects (nullifiers, note commitments, and enqueued public calls) that the sequencer then applies in public, keeping your vote private while the tally stays public.

Related reading: [transactions](https://docs.aztec.network/developers/docs/foundational-topics/transactions), [state management](https://docs.aztec.network/developers/docs/foundational-topics/state_management)

## What is private composability?[​](#what-is-private-composability)

On Aztec, smart contracts can call each other privately. Because transactions execute and prove locally, not only the state but the call stack itself can stay private: nobody watching the chain learns which contract called which. This video explains how that lets you build on top of other apps permissionlessly, just like Ethereum, without leaking what you are doing.

Related reading: [call types](https://docs.aztec.network/developers/docs/foundational-topics/call_types), [calling other contracts](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts)

## How authorization works (authwits)[​](#how-authorization-works-authwits)

Authentication witnesses (authwits) are Aztec's generalized alternative to Ethereum's approve and transferFrom pattern: they authorize a specific action for a specific caller, work in both private and public execution, and prevent replay. This lesson walks through the message hash structure, the private and public flows, and the `#[authorize_once]` macro.

Related reading: [authentication witness concepts](https://docs.aztec.network/developers/docs/foundational-topics/advanced/authwit), [using authwits in aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses)

## Get started in under 60 seconds[​](#get-started-in-under-60-seconds)

Ready to build? This video walks through installing the Aztec tooling, creating a new contract project, compiling it, and deploying it to a local network, all in under a minute.

Related reading: [getting started on a local network](https://docs.aztec.network/developers/getting_started_on_local_network)

## More videos[​](#more-videos)

For a full-length course and more explainers, visit the [Aztec Network YouTube channel](https://www.youtube.com/@aztecnetwork).

**Tags:**
- [videos](https://docs.aztec.network/developers/tags/videos)
- [learning](https://docs.aztec.network/developers/tags/learning)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/resources/video_lessons.mdx)