# CORDIC

This document aims to explain a little bit what the algorithm CORDIC
does and how powerful it is. Most of this document is based on the paper
[50 Years of CORDIC: Algorithms, Architectures,and
Applications](https://core.ac.uk/download/pdf/192192882.pdf).

## Introduction

CORDIC is an abbreviation of COordinate Rotation DIgital Computer, and
as its name suggests, it is an algorithm, or a computer if you will,
that does coordinate rotation and this coordinates can be either
carthesian or hyperbolic. The key concept of CORDIC arithmetic is based
on the simple and ancient principles of two-dimensional geometry.

A base rotation into a two-dimensional space could be represented as

```math
\bold{p} = \bold{Mx}
```

where $\bold{x}$ is the 2D-input and

```math
\bold{M} = \begin{bmatrix}
cos(\theta) & -sin(\theta) \\
sin(\theta) & cos(\theta)
\end{bmatrix}
```

where $\theta$ is the rotational angle.

It also could be represented as a multiplication in the complex plain,
being represented as

```math
y = x \cdot e^{jw}
```

where $x$ is the complex input, $w$ is the rotational angle, and $y$ the
complex output.

## The Algorithm

The CORDIC algorithm uses these concepts explained above and some math
to make calculus based on those 2D rotations using just low-cost
computation (e.g. bit shifting, addition, subtraction..).
This algorithm is based in the premise that we can replace the rotation
$\theta$ by multiple predefined rotations that could change just the
direction. Those rotations are $\alpha_i = tan^{-1}(2^{-i})$, then
$tan (\alpha_i) = 2^{-i}$ and those rotations could be easily
implemented in hardware.

Considering the matrix $\bold{M}$, we could rewrite it as

```math
\bold{M} = \left [ (1+ tan^{-1} \theta )^{-1} \right ] \begin{bmatrix}
1 & -tan (\theta) \\
tan (\theta) & 1
\end{bmatrix}
```

We can implement those rotations using just the rotations predefined
above. Although, we might consider that there is the value $ [ (1+
tan^{-1} \theta )^{-1}]$ to be calculated. Thus, if we apply the same
micro-rotations, this transforms into multiple constants, i.e., just one
constant that could be defined as

```math
K = K_i = \prod 1/ \sqrt{(1+2^{-2i})} \approx 1.6467605
```

which you can find in the [cordic test code](../tests/test_cordic.py)
line 314, used to callibrate the cordic output to the expected output.

The directions of the micro-rotations is defined by $\sigma_i$. Thus the
$i$-rotation would be

```math
\bold{R_i} = \begin{bmatrix}
1 & -\sigma_i 2^{-i}  \\
\sigma_i 2^{-i} & 1
\end{bmatrix}
```

Thus, the output of the $i$-rotation are

```math
x_{i+1} = x_i - \sigma 2^{-1}y_i
```
```math
y_{i+1} = y_i + \sigma 2^{-1}y_i
```
```math
w_{i+1} = w_i - \sigma \alpha_i
```

## Generalization of the algorithm

The math showed can be generalized to not just circular rotation but to
a bunch of other calculi. This table show all the possible ways we could
levarage CORDIC to calculate

| $m$ | Rotation mode                             | Vectoring mode                    |
|-----|-------------------------------------------|-----------------------------------|
| 1   | $x_n = K(x_0\cos w_0 + y_0\sin w_0 )$     | $x_n = K\sqrt{x_0^2+y_0^2}$       |
| 1   | $y_n = K(y_0\cos w_0 -  y_0\sin w_0 ) $   | $y_n = 0$                         |
| 1   | $w_n = 0$                                 | $w_n = w_0 + \tan^{-1}(y_0/x_0)$  |
| 0   | $x_n = x_0$                               | $x_n = x_0 $                      |
| 0   | $y_n = y_0 + x_0 \cdot w_0 $              | $y_n = 0$                         |
| 0   | $w_n = 0$                                 | $w_n = w_0 + y_0/x_0$             |
| -1  | $x_n = K(x_0\cosh w_0 + y_0\sinh w_0 )$   | $x_n = K\sqrt{x_0^2+y_0^2}$       |
| -1  | $y_n = K(y_0\cosh w_0 -  y_0\sinh w_0 ) $ | $y_n = 0$                         |
| -1  | $w_n = 0$                                 | $w_n = w_0 + \tanh^{-1}(y_0/x_0)$ |

and

```math
x_{i+1} = x_i - m \sigma \cdot 2^{-1} \cdot y_i
```
```math
y_{i+1} = y_i + \sigma \cdot 2^{-1} \cdot y_i
```
```math
w_{i+1} = w_i - \sigma \alpha_i
```

where

```math
\sigma = \begin{cases}
    sign(z_i), \text{for rotation mode} \\
    -sign(y_i), \text{for vectoring mode}
\end{cases}
```

Although, because the convergence range is from $-\pi/2$ to $\pi/2$, to
calculate the other quadrants you ought to change input as

```math
x_0 = -x_{-1}
```
```math
y_0 = -y_{-1}
```
```math
w_0 = w_{-1}+\pi
```

when rotation mode and $w_0$ is out of the range, or when vectoring mode
and $x_{-1}$ is negative.

You can find those statements in [the code](../src/sdr-tools/cordic_step_rotation.v) using the names `alpha`,
`sigma`, `M`, `MODE`, etc.
