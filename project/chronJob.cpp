#include <iostream>
#include <chrono>
#include <thread>
#include <functional>
using namespace std;

void startTimer(function<void(void)> f, unsigned int interval) {
    thread([f, interval](){
        while(true) {
            auto x = chrono::steady_clock::now() + chrono::milliseconds(interval);
            f();
            this_thread::sleep_until(x);
        }
    }).detach();
}

int cur_q = 230;
int max_q = 900;
int q_ref = 200;
double p = 0;
int e_thres = 40;
double kp = 0.00014723;
double ki;
int e_old = 0;
double k1 = 0.5;
double ki0 = 0.0000004277;
double e;
unsigned int sampling_freq = 60;

int myMod(int x) {
    return x<0 ? -x : x;
}

void calcP()
{
    e = cur_q - q_ref;
    int e_diff = e - e_old;
    if(myMod(e) > e_thres) {
        ki = ki0 * (1 + ((myMod(e) - e_thres) / (2 * e_thres)));
    }
    else if ((e * e_diff) < 0) {
        ki = ki0 * k1;
    } 
    else {
        ki = ki0;
    }
    p = p + kp*e_diff + ki * e;
    p = p > 1 ? 1 : (p < 0 ? 0 : p);
    e_old = e;
    cout << "calculating probability: " <<p<<"\n";
}

// void enque() {
//     p = p * (cur_q / q_ref);
//     p = p > 1 ? 1 : (p < 0 ? 0 : p);
//     double r = rand();
//     if(cur_q + 1 == q_lim || r <= p) {
//         // packet drop
//     }
//     else {
//         // packet enque
//     }
// }

int main()
{
  startTimer(calcP, sampling_freq);
  while (true) {

  }
  // return 0;
}