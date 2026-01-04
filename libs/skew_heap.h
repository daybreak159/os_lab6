#ifndef __LIBS_SKEW_HEAP_H__
#define __LIBS_SKEW_HEAP_H__

/*
 * 斜堆（Skew Heap）：一种实现“优先队列”的自调整堆结构。
 *
 * - 斜堆支持快速 merge/insert/remove，从而可以维护“最小值优先”的队列。
 * - lab6 的 Stride Scheduling 会把 run_queue 看作一个优先队列：stride/pass 最小的进程优先运行，
 *   因此需要这类数据结构来避免每次 pick_next 都线性扫描整个队列。
 *
 * 说明：
 * - skew_heap_entry 只是节点指针域；具体元素（例如 proc_struct）通过“嵌入字段 + le2xxx 宏”找回宿主结构体。
 * - comp(a,b) 由上层提供，决定队列顺序；在 Stride 中 comp 会比较两个进程的 stride，并处理无符号溢出比较问题。
 */

struct skew_heap_entry {
     struct skew_heap_entry *parent, *left, *right;
};

typedef struct skew_heap_entry skew_heap_entry_t;

typedef int(*compare_f)(void *a, void *b);

static inline void skew_heap_init(skew_heap_entry_t *a) __attribute__((always_inline));
static inline skew_heap_entry_t *skew_heap_merge(
     skew_heap_entry_t *a, skew_heap_entry_t *b,
     compare_f comp);
static inline skew_heap_entry_t *skew_heap_insert(
     skew_heap_entry_t *a, skew_heap_entry_t *b,
     compare_f comp) __attribute__((always_inline));
static inline skew_heap_entry_t *skew_heap_remove(
     skew_heap_entry_t *a, skew_heap_entry_t *b,
     compare_f comp) __attribute__((always_inline));

static inline void
skew_heap_init(skew_heap_entry_t *a)
{
     a->left = a->right = a->parent = NULL;
}

static inline skew_heap_entry_t *
skew_heap_merge(skew_heap_entry_t *a, skew_heap_entry_t *b,
                compare_f comp)
{
     if (a == NULL) return b;
     else if (b == NULL) return a;
     
     skew_heap_entry_t *l, *r;
     if (comp(a, b) == -1)
     {
          // a 更小：递归合并 (a->right, b)，并交换 a 的左右子树以达到“自调整”
          r = a->left;
          l = skew_heap_merge(a->right, b, comp);
          
          a->left = l;
          a->right = r;
          if (l) l->parent = a;

          return a;
     }
     else
     {
          // b 更小：递归合并 (a, b->right)，并交换 b 的左右子树
          r = b->left;
          l = skew_heap_merge(a, b->right, comp);
          
          b->left = l;
          b->right = r;
          if (l) l->parent = b;

          return b;
     }
}

static inline skew_heap_entry_t *
skew_heap_insert(skew_heap_entry_t *a, skew_heap_entry_t *b,
                 compare_f comp)
{
     skew_heap_init(b);
     return skew_heap_merge(a, b, comp);
}

static inline skew_heap_entry_t *
skew_heap_remove(skew_heap_entry_t *a, skew_heap_entry_t *b,
                 compare_f comp)
{
     skew_heap_entry_t *p   = b->parent;
     // 删除节点 b：把 b 的左右子堆 merge 成一个替代子堆 rep，再接回父节点 p
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
     if (rep) rep->parent = p;
     
     if (p)
     {
          if (p->left == b)
               p->left = rep;
          else p->right = rep;
          return a;
     }
     else return rep;
}

#endif    /* !__LIBS_SKEW_HEAP_H__ */
