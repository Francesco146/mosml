#include <stdlib.h>

char foo[]="\377";
int main(int argc, char ** argv)
{
  int i;
  i = foo[0];
  exit(i != -1);
}
