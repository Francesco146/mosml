#include <signal.h>

int main(int argc, char ** argv)
{
  sig_t old;
  old = signal(SIGQUIT, SIG_DFL);
  return 0;
}
