#include <setjmp.h>

int main(int argc, char ** argv)
{
  jmp_buf buf;
  int i;
  i = _setjmp(buf);
  if (i == 0) {
    _longjmp(buf, 12345);
  }
  exit (i != 12345);
}
