# AI registry

As discussed in the interview, and for the sake of transparency, I list here the tasks/prompts I've given to Claude Code to help me.

I use AI for analysis, brainstorming, configuration issues, or simple refactoring (naming changes, basic documentation, scaffolding...).

Every suggestion (but the small refactors) is manually done by me after review. 


## Claude chatbot

When doing the initial implementation I didn't want any extra help, so I used the chat bot with no context at all just to generate regex patterns. [Here](https://claude.ai/share/4c4d1880-6a8a-4e67-a655-32f955e756b3) is the full chat.

## Claude code log

1. After finishing the first version I wanted an overview of the project to see if I was missing something from the requirements. [Here](./claude_code_chats/1_first_version_review.md) is the chat attached. It's true that I forgot about the extra requirements! About the connections. The rest of the agent output is useless right now.

2. I used it to find the cause of an unexpected return in a test. I have many hardcoded Segment classes as fixtures and I couldn't find the typo. I had `Segment.new('Train', 'BCN', 'NYC',...`, it's a Flight obviously.

3. I had an issue where Simplecov was not covering the whole lib folder. I needed that to check whether I should add more unit tests or not. After doing some research I asked the agent. [Here](./claude_code_chats/2_simplecov_issue.md) is the chat. Simplecov just reports files that gets required in the test suite. I haven't created tests for every file yet, woops!

4. I needed to feel more confident with the decision of using `.send` in the `Itinerary` class, for making it more scalable. And also an extra hand on how to unit test the method. [Here](./claude_code_chats/3_send_method_and_test.md) is the conversation. Everything is good, it showed me how to safeguard it with `respond_to`, and guided me on the mocking situation for the unit tests.

5. After testing everything, I wanted to review the requirements again. [Here](./claude_code_chats/4_second_review.md) is the review. It flagged some issues (that I would have found), and pending tasks (fix the TODOs, missing tests).

6. Architectural / design analysis. This is something I always do to confirm if my design is "the best". Instead of asking the AI my hypothesis, I tell them the use cases to see if they arrive to the same conclusion (it's not easy to avoid biasing the model). In this case, I think the library is not very extensible:

If a new client arrives and asks me to parse their client input.json into itineraries.pdf, it's easy to create a new JsonParser and PdfFormatter, but if I modify the travel_manager.rb I break the FCM implementation. That's why I thought about making the travel_manager agnostic to the parsing/format implementations.

It's also true that I am inventing new use cases, and it's not possible to make it easy to modify for every use case: what if the new client wants different sorting rules? should I also make it agnostic for that?

Classic overengineering!!

[Here](./claude_code_chats/5_architecture_design_first_review.md) is the conversation. Some of the ideas were just to double check.

7. I ask CC to refactor the code to remove time_from and time_to from the Segment initializer, and use keyword arguments. This is specially useful when dealing with multiple arguments. It also suggested moving TimeUtils.to_time outside the Segment class (decoupling), I think it's a great idea. [Here](./claude_code_chats/6_refactor_keyword_arguments) is the plan.

8. Asked CC to add YARD to TimeUtils, and make suggestions about the module. Changed to_hour to to_time, simplified guard in to_time, simplified same_dates (using `Date.to_date` ). The yard is too much, I'm removing the examples and I'm simplifying the descrptions. [Full log](./claude_code_chats/7_document_time_utils.md).

9. Asked CC to check where is the Yard missing: [Log](./claude_code_chats/8_find_missing_yard_docs.md).

10. Asked CC to refactor my classes to use the `class << self` syntax for class methods: [Log](./claude_code_chats/9_refactor_class_methods).

11. Asked CC for a full QA review. I used ChatGPT to make the prompts (chat [here](https://chatgpt.com/share/69c99c32-7e88-8331-b821-ef0cf2aeafde)) - very very useful by the way. And then got the full analysis [here](./claude_code_chats/10_test_suite_review.md). It gave me some untested corner cases.

12. After reviewing all the tests, I want another review with the same prompts. It gave me new corner cases to test (even though the code didn't change), but most of them were hallucinations. [New plan](./claude_code_chats/11_test_strategy.md).

13. Asked for a list of missing / inconsistencies in YARD documentation. [Log](./claude_code_chats/12_yard_inconsistencies.md)

14. Claude code made [this](../spec/lib/travel_manager/time_utils_spec.rb:59) regression test to check for DST transitions issues.

15. Created some review prompts with ChatGPT [here](https://chatgpt.com/share/69cd86c6-260c-8333-8893-3b0609837c1d):
    1. [Requirements coverage](./claude_code_chats/13_review_requirements.md). All good. Just a minor bug in the `connection?` method.
    2. [Extensibility analysis](./claude_code_chats/14_extensibility_analysis.md). This is very helpful in order to have ideas to improve the project further in the future. However, I feel it's very biased because of the ideas I mentioned in the [decisions document](decisions.md). As always, balance between abstraction, and scope is they key.
    3. [Technical code review](./claude_code_chats/15_technical_code_review.md). _"The issues below are refinements, not red flags."_ Happy face. This is not the first time I read about the FileRead not being safe enough, so I'm rescuing broadly as suggested. About the TextFormatter test, I already run QA reviews multiple times and this is the first time I read this. I think it's well covered. Very good Medium issues, I did them all but 6 and 9. I did Low issues as well but the number 11. Very good prompt.
    4. [UX review](./claude_code_chats/16_ux_review.md). Very good insights, specially with consistency. Changed several error messages.

## AI Learnings

- Prompts.
- Skills.
- Agent orchestration: https://code.claude.com/docs/en/agent-teams. 
- Token usage.