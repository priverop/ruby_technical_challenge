# AI registry

As discussed in the interview, and for the sake of transparency, I list here the tasks/prompts I've given to Claude Code to help me.

## Claude chatbot

When doing the initial implementation I didn't want any extra help, so I used the chat bot with no context at all. [Here](https://claude.ai/share/4c4d1880-6a8a-4e67-a655-32f955e756b3) is the full chat.

<!-- TODO -->
- Regex to parse travel lines. 

## Claude code

1. After finishing the first version I wanted an overview of the project to see if I was missing something from the requirements. [Here](./claude_code_chats/1_first_version_review.md) is the chat attached. It's true that I forgot about the extra requirements! about the connections. The rest of the agent output is useless right now.

2. I used it to find the cause of an unexpected return in a test. I have many hardcoded Segment classes as fixtures and I couldn't find the typo. I had `Segment.new('Train', 'BCN', 'NYC',...`, it's a Flight obviously.

3. I had an issue where Simplecov was not covering the whole lib folder. I needed that to check whether I should add more unit tests or not. After doing some research I asked the agent. [Here](./claude_code_chats/2_simplecov_issue.md) is the chat. Simplecov just reports files that gets required in the test suite. I haven't created tests for every file yet, woops!

4. I needed to feel more confident with the decision of using `.send` in the `Itinerary` class, for making it more scalable. And also an extra hand on how to unit test the method. [Here](./claude_code_chats/3_send_method_and_test.md) is the conversation. Everything is good, it showed me how to safeguard it with `respond_to`, and guided me on the mocking situation for the unit tests.

5. After testing everything, I wanted to review the requirements again. [Here](./claude_code_chats/4_second_review.md) is the review. It flagged some issues (that I would have found), and pending tasks (fix the TODOs, missing tests).

6. Architectural / design analysis. This is something I always do to confirm if my design is "the best". Instead of asking the AI my hypothesis, I tell them the use cases to see if they arrive to the same conclusion (it's not easy to avoid biase the model). In this case, I think the library is not very extensible:

If a new client arrives and asks me to parse their client input.json into itineraries.pdf, it's easy to create a new JsonParser and PdfFormatter, but if I modify the travel_manager.rb I break the FCM implementation. That's why I thought about making the travel_manager agnostic to the parsing/format implementations.

It's also true that I am inventing new use cases, and it's not possible to make it easy to modify for every use case: what if the new client wants different sorting rules? should I also make it agnostic for that?

Classic overengineering!!

[Here](./claude_code_chats/5_architecture_design_first_review.md) is the conversation. Some of the ideas were just to double check.

1. I ask CC to refactor the code to remove time_from and time_to from the Segment initializer, and use keyword arguments. This is specially useful when dealing with multiple arguments. It also suggested moving TimeUtils.to_time outside the Segment class (decoupling), I think it's a great idea. [Here](./claude_code_chats/6_refactor_keyword_arguments) is the plan.