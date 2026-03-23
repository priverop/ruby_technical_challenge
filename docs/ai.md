# AI registry

As discussed in the interview, and for the sake of transparency, I list here the tasks/prompts I've given to Claude Code to help me.

## Claude chatbot

When doing the initial implementation I didn't want any extra help, so I used the chat bot with no context at all. [Here](https://claude.ai/share/4c4d1880-6a8a-4e67-a655-32f955e756b3) is the full chat.

<!-- TODO -->
- Regex to parse travel lines. 

## Claude code

1. After finishing the first version I wanted an overview of the project to see if I was missing something from the requirements. [Here](./claude_code_chats/1_first_version_review.md) is the chat attached. It's true that I forgot about the extra requirements! about the connections. The rest of the agent output is useless right now.

2. I used it to find the cause of an unexpected return in a test. I have many hardcoded Segment classes as fixtures and I couldn't find the typo. I had `Segment.new('Train', 'BCN', 'NYC',...`, it's a Flight obviously.