package utils

import (
	"sync"
)

type Queue struct {
	lock   *sync.Mutex
	Values []map[string]interface{}
}

func Init() Queue {
	return Queue{&sync.Mutex{}, make([]map[string]interface{}, 0)}
}

func (q *Queue) Enqueue(x map[string]interface{}) {
	for {
		q.lock.Lock()
		q.Values = append(q.Values, x)
		q.lock.Unlock()
		return
	}
}

func (q *Queue) Dequeue() *map[string]interface{} {
	for {
		if len(q.Values) > 0 {
			q.lock.Lock()
			x := q.Values[0]
			q.Values = q.Values[1:]
			q.lock.Unlock()
			return &x
		}
		return nil
	}
}

//// Initialize queue
//queue := &Queue{
//items: list.New(),
//}
//// Add items to queue
//queue.Enqueue("test 1")
//queue.Enqueue("test 2")
//fmt.Println("Size: " + strconv.Itoa(queue.Size()))
//// Process items until size > 0
//for queue.Size() > 0 {
//// Get next value
//value, err := queue.Front()
//if err == nil {
//fmt.Printf("Value: %s\n", value.Value)
//// Remove item from queue
//queue.Dequeue()
//}
//}
//// Output:
////Size: 2
////Value: test 1
////Value: test 2
////Size: 0
//fmt.Printf("Size: %d\n", queue.Size())
