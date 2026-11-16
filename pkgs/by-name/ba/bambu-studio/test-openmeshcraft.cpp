// Booleans of two unit-offset cubes through the wrapper Bambu Studio calls.
#include <OpenMeshCraft/OpenMeshCraftBoolean.h>

#include <cmath>
#include <cstdio>
#include <vector>

static std::vector<BambuOMCPoint> cube_points(double lo, double hi)
{
    std::vector<BambuOMCPoint> points;
    for (double x : {lo, hi})
        for (double y : {lo, hi})
            for (double z : {lo, hi})
                points.push_back({x, y, z});
    return points;
}

// Outward-facing triangles for the vertex order of cube_points().
static const std::vector<BambuOMCTriangle> cube_triangles = {
    {{0, 1, 3}}, {{0, 3, 2}}, {{4, 6, 7}}, {{4, 7, 5}}, {{0, 4, 5}}, {{0, 5, 1}},
    {{2, 3, 7}}, {{2, 7, 6}}, {{0, 2, 6}}, {{0, 6, 4}}, {{1, 5, 7}}, {{1, 7, 3}},
};

static void volume(const BambuOMCPoint *p, size_t, const BambuOMCTriangle *t, size_t count, void *out)
{
    double sum = 0;
    for (size_t i = 0; i < count; ++i) {
        const BambuOMCPoint &a = p[t[i].vertices[0]], &b = p[t[i].vertices[1]], &c = p[t[i].vertices[2]];
        sum += a.x * (b.y * c.z - b.z * c.y) - a.y * (b.x * c.z - b.z * c.x) + a.z * (b.x * c.y - b.y * c.x);
    }
    *static_cast<double *>(out) = sum / 6;
}

int main()
{
    const auto first_points = cube_points(0, 2), second_points = cube_points(1, 3);
    const BambuOMCMesh first{first_points.data(), 8, cube_triangles.data(), 12};
    const BambuOMCMesh second{second_points.data(), 8, cube_triangles.data(), 12};

    const struct { BambuOMCOperation operation; const char *name; double expected; } cases[] = {
        {BAMBU_OMC_UNION, "union", 15},
        {BAMBU_OMC_INTERSECTION, "intersection", 1},
        {BAMBU_OMC_SUBTRACTION, "subtraction", 7},
    };

    int failed = 0;
    for (const auto &c : cases) {
        double result = 0;
        char error[256] = "";
        const bool ok = bambu_omc_boolean(&first, &second, c.operation, volume, &result, error, sizeof(error));
        std::printf("%s: volume %g, expected %g %s\n", c.name, result, c.expected, error);
        if (!ok || std::fabs(result - c.expected) > 1e-9)
            ++failed;
    }
    return failed;
}
