<?php

declare(strict_types=1);

namespace Tests\Feature\Http\Controllers;

use App\Models\User;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Auth & authorization coverage for the /api/cruce/* endpoints (CQ-004 / DA-G5).
 * Verifies the plan.md §5.2 role matrix is actually enforced by middleware:
 *   - unauthenticated  -> 401
 *   - wrong role       -> 403
 *   - correct role     -> passes the gate (not 401/403)
 */
class CruceAuthTest extends TestCase
{
    // ---- Unauthenticated: everything under /cruce is blocked ----

    #[Test]
    public function unauthenticated_requests_are_rejected_with_401(): void
    {
        $this->get('/api/cruce/lotes')->assertUnauthorized();
        $this->getJson('/api/cruce/lotes')->assertUnauthorized();
        $this->postJson('/api/cruce/upload')->assertUnauthorized();
        $this->deleteJson('/api/cruce/limpiar')->assertUnauthorized();
    }

    // ---- Destructive endpoints: admin only ----

    #[Test]
    public function limpiar_is_forbidden_for_non_admin_roles(): void
    {
        foreach ([User::ROLE_ADMISIONES, User::ROLE_MARKETING] as $role) {
            $user = User::factory()->role($role)->create();

            $this->actingAs($user)
                ->deleteJson('/api/cruce/limpiar')
                ->assertForbidden();
        }
    }

    #[Test]
    public function reprocesar_is_forbidden_for_non_admin_roles(): void
    {
        $user = User::factory()->role(User::ROLE_MARKETING)->create();

        $this->actingAs($user)
            ->postJson('/api/cruce/lotes/1/reprocesar')
            ->assertForbidden();
    }

    // ---- Write endpoints: admin + admisiones ----

    #[Test]
    public function upload_is_forbidden_for_marketing(): void
    {
        $user = User::factory()->role(User::ROLE_MARKETING)->create();

        $this->actingAs($user)
            ->postJson('/api/cruce/upload')
            ->assertForbidden();
    }

    #[Test]
    public function upload_passes_the_gate_for_admisiones(): void
    {
        $user = User::factory()->role(User::ROLE_ADMISIONES)->create();

        // No file attached -> controller returns 422, but crucially NOT 401/403:
        // the auth + role gate let the request through to the controller.
        $response = $this->actingAs($user)->postJson('/api/cruce/upload');

        $response->assertStatus(422);
    }

    // ---- Read endpoints: all three roles ----

    #[Test]
    public function read_endpoints_allow_marketing(): void
    {
        $user = User::factory()->role(User::ROLE_MARKETING)->create();

        $this->actingAs($user)
            ->getJson('/api/cruce/lotes')
            ->assertOk();
    }

    #[Test]
    public function a_user_without_role_is_forbidden_everywhere(): void
    {
        $user = User::factory()->create(); // role = null

        $this->actingAs($user)
            ->getJson('/api/cruce/lotes')
            ->assertForbidden();
    }

    // ---- Login flow ----

    #[Test]
    public function login_succeeds_with_valid_credentials_and_returns_role(): void
    {
        $user = User::factory()->role(User::ROLE_ADMIN)->create([
            'email' => 'admin@vonex.test',
        ]);

        $this->postJson('/api/login', [
            'email' => 'admin@vonex.test',
            'password' => 'password',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.role', User::ROLE_ADMIN);
    }

    #[Test]
    public function login_fails_with_invalid_credentials(): void
    {
        User::factory()->create(['email' => 'admin@vonex.test']);

        $this->postJson('/api/login', [
            'email' => 'admin@vonex.test',
            'password' => 'wrong-password',
        ])->assertStatus(422);
    }
}
