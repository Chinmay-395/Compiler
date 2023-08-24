; Ryan Clark & Enrique Valentino
; inserts an element into the MIDDLE of a linked list
%node = type { i64, %node* }

@nodeA = global %node { i64 1, %node* @nodeB }
@nodeB = global %node { i64 2, %node* @nodeC }
@nodeC = global %node { i64 4, %node* null }

@nodeD = global %node { i64 3, %node* null } ; node to be inserted

; based on the C code from: https://www.geeksforgeeks.org/insertion-in-linked-list/\
; for inserting after a node (not at the end)
define void @insertAfter(%node* %previous_node, %node* %new_node) {

    %new_node_next_pointer = getelementptr %node, %node* %new_node, i32 0, i32 1
    %previous_node_next_pointer = getelementptr %node, %node* %previous_node, i32 0, i32 1 ; previous node's next pointer

    ;set new node's next pointer to previous node's next pointer
    store %node* %previous_node_next_pointer, %node* %new_node_next_pointer

    ;set previous node's next pointer to address of new_node
    store %node* %new_node, %node* %previous_node_next_pointer

    ret void
}

define i64 @main(i64 %argc, i8** %arcv) {

  call void @insertAfter(%node* @nodeB, %node* @nodeD)

  %head = getelementptr %node, %node* @nodeA, i32 0, i32 0 ;nodeA's value pointer
  %link = getelementptr %node, %node* @nodeA, i32 0, i32 1 ;nodeA's next pointer
  %next = load %node*, %node** %link ;load nodeB
  %val = getelementptr %node, %node* %next, i32 0, i32 0 ;nodeB's value pointer

  %link2 = getelementptr %node, %node* %next, i32 0, i32 1 ;nodeB's next pointer
  %next2 = load %node*, %node** %link2 ;load NodeD
  %val2 = getelementptr %node, %node* %next2, i32 0, i32 0 ;nodeD's value pointer

  ;shows that the node was inserted at the third position
  %1 = load i64, i64* %val2 

  ret i64 %1
}