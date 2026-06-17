
```text
1. Use the lab content as background information. Don’t answer anything yet. I’ll ask questions later.   
2. First, list all the task titles in plain text with no blank lines.  
```



```text
1. Wrap all the task titles using the following code. Don’t change the format.

2. Extract all the Bash code (no JavaScript, JSON, etc. code blocks) from the lab content and replace <code> with the corresponding code exactly as it appears. Do not put code within EOF.

3. For multiple-choice questions, extract each question, identify the correct answer, and present the results in the following format:

Question 1: <question>
Answer: <correct answer>

Question 2: <question>
Answer: <correct answer>

Continue this format for all multiple-choice questions found in the lab. For each task, restart the question numbering from 1. Number questions sequentially within the same task only, and reset the numbering when a new task begins.

4. If there is no code or questions, remove the placeholders and reduce the blank lines properly.

5. Output the text in a code block.

cat << 'EOF'

========================================================
Task 1. ...
========================================================

<questions>

EOF

cat << 'EOF'

========================================================
Task 2. ...
========================================================

EOF

<code> 

cat << 'EOF'

========================================================
Task 3. ...
========================================================

<questions>

EOF

<code>

echo -e "\n✅  All done\n"
```

