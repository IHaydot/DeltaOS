.PHONY: push1 
push1: 
    git add *  
    git commit -m "changes" 
    git push master master
    make delete_build 
.PHONY: push2 
push2: 
    git add * 
    git commit -m "changes"
    git push master1 master
    make delete_makes
.PHONY: delete_build 
delete_build: 
    git rm --cached boot/ kernel/ target/ deltaos-amd64.osi qemu-logs -r
    git commit -m "deletions"
    git push master master
.PHONY: delete_makes 
delete_makes: 
    git rm --cached makefile buildenv -r
    git commit -m "deletes"
    git push master1 master
